BEGIN;

CREATE VIEW v_asset_uptime AS
WITH bounds AS (
    SELECT date_trunc('day', min(downtime_start)) AS period_start,
           date_trunc('day', max(COALESCE(downtime_end, now()))) + interval '1 day' AS period_end
    FROM downtime_events
), unplanned AS (
    SELECT asset_id, sum(EXTRACT(epoch FROM (COALESCE(downtime_end, now()) - downtime_start))/60.0) AS downtime_minutes
    FROM downtime_events WHERE NOT planned GROUP BY asset_id
)
SELECT a.asset_id, a.asset_code, a.name AS asset_name, b.period_start, b.period_end,
       COALESCE(u.downtime_minutes,0)::numeric(14,2) AS unplanned_downtime_minutes,
       CASE WHEN b.period_start IS NULL THEN NULL ELSE
         round(100 * GREATEST(0, EXTRACT(epoch FROM (b.period_end-b.period_start))/60.0 - COALESCE(u.downtime_minutes,0)) /
               NULLIF(EXTRACT(epoch FROM (b.period_end-b.period_start))/60.0,0),2) END AS uptime_percent
FROM assets a CROSS JOIN bounds b LEFT JOIN unplanned u USING (asset_id);

CREATE VIEW v_line_uptime AS
WITH bounds AS (
    SELECT date_trunc('day', min(downtime_start))::date AS start_date,
           date_trunc('day', max(COALESCE(downtime_end, now())))::date AS end_date FROM downtime_events
), available AS (
    SELECT l.line_id, b.start_date, b.end_date,
           CASE WHEN b.start_date IS NULL THEN NULL ELSE ((b.end_date-b.start_date+1) *
             (SELECT sum(EXTRACT(epoch FROM ((CASE WHEN end_time <= start_time THEN end_time + interval '1 day' ELSE end_time END)-start_time))/60.0)
              FROM shifts WHERE function='PRODUCTION' AND active)) END AS available_minutes
    FROM production_lines l CROSS JOIN bounds b
), impacts AS (
    SELECT alr.line_id, sum(EXTRACT(epoch FROM (COALESCE(d.downtime_end,now())-d.downtime_start))/60.0) AS downtime_minutes
    FROM downtime_events d JOIN asset_line_relationships alr USING (asset_id)
    WHERE NOT d.planned
      AND (alr.relationship_type <> 'SCHEDULED_SHARED' OR EXISTS (
          SELECT 1 FROM asset_production_schedule aps WHERE aps.asset_id=d.asset_id AND aps.line_id=alr.line_id
          AND aps.scheduled_start < COALESCE(d.downtime_end,now()) AND aps.scheduled_end > d.downtime_start))
    GROUP BY alr.line_id
)
SELECT l.line_id, l.line_code, l.name AS line_name, a.start_date, a.end_date,
       a.available_minutes::numeric(14,2), COALESCE(i.downtime_minutes,0)::numeric(14,2) AS unplanned_downtime_minutes,
       CASE WHEN a.available_minutes IS NULL THEN NULL ELSE round(100*GREATEST(0,a.available_minutes-COALESCE(i.downtime_minutes,0))/NULLIF(a.available_minutes,0),2) END AS uptime_percent
FROM production_lines l JOIN available a USING(line_id) LEFT JOIN impacts i USING(line_id);

CREATE VIEW v_plant_uptime AS
SELECT s.site_id, s.site_code, min(lu.start_date) AS start_date, max(lu.end_date) AS end_date,
       sum(lu.available_minutes)::numeric(14,2) AS available_minutes,
       sum(lu.unplanned_downtime_minutes)::numeric(14,2) AS unplanned_downtime_minutes,
       round(100*(sum(lu.available_minutes)-sum(lu.unplanned_downtime_minutes))/NULLIF(sum(lu.available_minutes),0),2) AS uptime_percent
FROM sites s JOIN production_lines l USING(site_id) JOIN v_line_uptime lu USING(line_id) GROUP BY s.site_id,s.site_code;

CREATE VIEW v_pm_compliance AS
SELECT date_trunc('month', scheduled_date)::date AS period,
       count(*) AS scheduled_count,
       count(*) FILTER (WHERE status='COMPLETED' AND completed_date <= scheduled_date) AS completed_on_time_count,
       round(100.0*count(*) FILTER (WHERE status='COMPLETED' AND completed_date <= scheduled_date)/NULLIF(count(*),0),2) AS compliance_percent
FROM pm_executions GROUP BY 1;

CREATE VIEW v_emergency_work_percentage AS
SELECT date_trunc('month', requested_at)::date AS period, count(*) AS total_work_orders,
       count(*) FILTER (WHERE emergency) AS emergency_work_orders,
       round(100.0*count(*) FILTER (WHERE emergency)/NULLIF(count(*),0),2) AS emergency_percent
FROM work_orders GROUP BY 1;

CREATE VIEW v_mttr AS
SELECT a.asset_id,a.asset_code,count(*) AS qualifying_repairs,
       round(avg(EXTRACT(epoch FROM (w.work_completed_at-w.work_started_at))/60.0),2) AS mttr_minutes
FROM work_orders w JOIN assets a USING(asset_id)
WHERE w.work_type IN ('CORRECTIVE','EMERGENCY') AND w.work_started_at IS NOT NULL AND w.work_completed_at IS NOT NULL
GROUP BY a.asset_id,a.asset_code;

CREATE VIEW v_mtbf AS
WITH sequenced AS (
 SELECT f.asset_id,f.failure_time,lag(f.failure_time) OVER(PARTITION BY f.asset_id ORDER BY f.failure_time) previous_failure
 FROM failure_events f
)
SELECT a.asset_id,a.asset_code,count(*) FILTER(WHERE s.previous_failure IS NOT NULL) AS intervals,
       round(avg(EXTRACT(epoch FROM (s.failure_time-s.previous_failure))/3600.0) FILTER(WHERE s.previous_failure IS NOT NULL),2) AS mtbf_hours
FROM assets a LEFT JOIN sequenced s USING(asset_id) GROUP BY a.asset_id,a.asset_code;

CREATE VIEW v_critical_response_time AS
SELECT date_trunc('month',requested_at)::date AS period,count(*) AS critical_breakdowns,
       round(avg(EXTRACT(epoch FROM (acknowledged_at-requested_at))/60.0),2) AS average_response_minutes
FROM work_orders WHERE priority='CRITICAL' AND work_type IN ('EMERGENCY','CORRECTIVE') AND acknowledged_at IS NOT NULL GROUP BY 1;

CREATE VIEW v_repeat_failures AS
SELECT date_trunc('month',failure_time)::date AS period,a.asset_code,failure_mode,count(*) AS failure_count,
       count(*) FILTER(WHERE repeat_failure) AS repeat_failure_count
FROM failure_events f JOIN assets a USING(asset_id) GROUP BY 1,a.asset_code,failure_mode;

CREATE VIEW v_work_order_closure_rate AS
SELECT date_trunc('month',requested_at)::date AS period,count(*) AS work_order_count,
       count(*) FILTER(WHERE status='CLOSED') AS closed_count,
       round(100.0*count(*) FILTER(WHERE status='CLOSED')/NULLIF(count(*),0),2) AS closure_percent
FROM work_orders GROUP BY 1;

CREATE VIEW v_critical_spare_availability AS
SELECT count(DISTINCT p.part_id) AS critical_part_count,
       count(DISTINCT p.part_id) FILTER(WHERE p.quantity_on_hand >= p.minimum_quantity) AS available_part_count,
       round(100.0*count(DISTINCT p.part_id) FILTER(WHERE p.quantity_on_hand >= p.minimum_quantity)/NULLIF(count(DISTINCT p.part_id),0),2) AS availability_percent
FROM parts p JOIN asset_parts ap USING(part_id) WHERE p.critical_spare OR ap.critical_for_asset;

CREATE VIEW v_downtime_by_asset AS
SELECT a.asset_id,a.asset_code,count(d.downtime_event_id) AS event_count,
       round(COALESCE(sum(EXTRACT(epoch FROM (COALESCE(d.downtime_end,now())-d.downtime_start))/60.0),0),2) AS downtime_minutes
FROM assets a LEFT JOIN downtime_events d USING(asset_id) GROUP BY a.asset_id,a.asset_code;

CREATE VIEW v_downtime_by_failure_mode AS
SELECT f.failure_mode,count(DISTINCT f.failure_event_id) AS failure_count,
       round(COALESCE(sum(EXTRACT(epoch FROM (COALESCE(d.downtime_end,now())-d.downtime_start))/60.0),0),2) AS downtime_minutes
FROM failure_events f LEFT JOIN downtime_events d ON d.work_order_id=f.work_order_id GROUP BY f.failure_mode;

CREATE VIEW v_planned_vs_reactive_work AS
SELECT date_trunc('month',requested_at)::date AS period,
       CASE WHEN planned THEN 'PLANNED' ELSE 'REACTIVE' END AS work_classification,
       count(*) AS work_order_count,round(sum(labor_hours),2) AS labor_hours
FROM work_orders GROUP BY 1,2;

CREATE VIEW v_planned_vs_reactive_overtime AS
SELECT date_trunc('month',cost_date)::date AS period,overtime_type,count(*) AS cost_entries,round(sum(amount),2) AS overtime_cost
FROM maintenance_costs WHERE cost_category='OVERTIME' GROUP BY 1,2;

CREATE VIEW v_open_critical_work_orders AS
SELECT w.work_order_number,a.asset_code,w.priority,w.title,w.requested_at,w.status,
       round(EXTRACT(epoch FROM (now()-w.requested_at))/3600.0,2) AS age_hours
FROM work_orders w LEFT JOIN assets a USING(asset_id)
WHERE w.priority='CRITICAL' AND w.status NOT IN ('CLOSED','CANCELLED');

CREATE VIEW v_overdue_pm AS
SELECT p.pm_code,a.asset_code,e.scheduled_date,e.status,CURRENT_DATE-e.scheduled_date AS days_overdue
FROM pm_executions e JOIN pm_plans p USING(pm_plan_id) JOIN assets a USING(asset_id)
WHERE e.status <> 'COMPLETED' AND e.status <> 'CANCELLED' AND e.scheduled_date < CURRENT_DATE;

CREATE VIEW v_open_rca_actions AS
SELECT r.rca_number,w.work_order_number,a.asset_code,c.corrective_action_id,c.action_description,c.action_type,c.due_date,
       c.due_date < CURRENT_DATE AS overdue
FROM corrective_actions c JOIN rca_events r USING(rca_event_id) JOIN work_orders w USING(work_order_id)
LEFT JOIN assets a USING(asset_id) WHERE c.completed_date IS NULL;

CREATE VIEW v_sanitation_maintenance_risk AS
SELECT sf.finding_number,a.asset_code,sf.reported_at,sf.priority,sf.startup_risk,sf.description,sf.status,w.work_order_number
FROM sanitation_findings sf LEFT JOIN assets a USING(asset_id) LEFT JOIN work_orders w USING(work_order_id)
WHERE sf.maintenance_required AND sf.status NOT IN ('RESOLVED','CLOSED');

CREATE VIEW v_shared_asset_risk AS
SELECT a.asset_code,alr.relationship_type,l.line_code,aps.scheduled_start,aps.scheduled_end,aps.production_order,
       CASE WHEN aps.scheduled_start <= now() AND aps.scheduled_end > now() THEN 'CURRENT_IMPACT'
            WHEN aps.scheduled_start > now() THEN 'FUTURE_RISK' ELSE 'DEPENDENCY' END AS risk_timing,
       EXISTS (SELECT 1 FROM downtime_events d WHERE d.asset_id=a.asset_id AND d.downtime_start <= now() AND COALESCE(d.downtime_end,now()+interval '1 second') > now()) AS asset_currently_down
FROM assets a JOIN asset_line_relationships alr USING(asset_id) JOIN production_lines l USING(line_id)
LEFT JOIN asset_production_schedule aps ON aps.asset_id=a.asset_id AND aps.line_id=l.line_id AND aps.scheduled_end >= now()
WHERE alr.relationship_type IN ('SCHEDULED_SHARED','SIMULTANEOUS_DEPENDENCY');

COMMIT;
