BEGIN;

CREATE OR REPLACE VIEW v_plant_uptime_monthly AS
WITH months AS (
    SELECT generate_series(DATE '2026-01-01',DATE '2026-08-01',interval '1 month')::date AS period
), available AS (
    SELECT period,
           EXTRACT(day FROM (period+interval '1 month'-interval '1 day'))*16*60*2 AS available_minutes
    FROM months
), downtime AS (
    SELECT date_trunc('month',d.downtime_start)::date period,
           sum(dal.delay_minutes) FILTER (WHERE dal.impact_type='IMMEDIATE') AS downtime_minutes
    FROM downtime_events d JOIN downtime_affected_lines dal USING(downtime_event_id)
    WHERE NOT d.planned GROUP BY 1
)
SELECT a.period,a.available_minutes::numeric(14,2),COALESCE(d.downtime_minutes,0)::numeric(14,2) unplanned_downtime_minutes,
       round(100.0*(a.available_minutes-COALESCE(d.downtime_minutes,0))/NULLIF(a.available_minutes,0),2) uptime_percent
FROM available a LEFT JOIN downtime d USING(period) ORDER BY period;

CREATE OR REPLACE VIEW v_line_uptime_monthly AS
WITH months AS (
 SELECT generate_series(DATE '2026-01-01',DATE '2026-08-01',interval '1 month')::date period
), available AS (
 SELECT m.period,l.line_id,l.line_code,l.name line_name,
        EXTRACT(day FROM (m.period+interval '1 month'-interval '1 day'))*16*60 AS available_minutes
 FROM months m CROSS JOIN production_lines l
), downtime AS (
 SELECT date_trunc('month',d.downtime_start)::date period,dal.line_id,
        sum(dal.delay_minutes) FILTER(WHERE dal.impact_type='IMMEDIATE') downtime_minutes
 FROM downtime_events d JOIN downtime_affected_lines dal USING(downtime_event_id)
 WHERE NOT d.planned GROUP BY 1,2
)
SELECT a.period,a.line_id,a.line_code,a.line_name,a.available_minutes::numeric(14,2),
       COALESCE(d.downtime_minutes,0)::numeric(14,2) unplanned_downtime_minutes,
       round(100.0*(a.available_minutes-COALESCE(d.downtime_minutes,0))/NULLIF(a.available_minutes,0),2) uptime_percent
FROM available a LEFT JOIN downtime d USING(period,line_id) ORDER BY period,line_code;

CREATE OR REPLACE VIEW v_pm_compliance_weekly AS
SELECT date_trunc('week',scheduled_date)::date period,count(*) scheduled_count,
       count(*) FILTER(WHERE status='COMPLETED' AND completed_date<=scheduled_date) completed_on_time_count,
       round(100.0*count(*) FILTER(WHERE status='COMPLETED' AND completed_date<=scheduled_date)/NULLIF(count(*),0),2) compliance_percent
FROM pm_executions GROUP BY 1 ORDER BY 1;

CREATE OR REPLACE VIEW v_pm_compliance_monthly AS
SELECT date_trunc('month',scheduled_date)::date period,count(*) scheduled_count,
       count(*) FILTER(WHERE status='COMPLETED' AND completed_date<=scheduled_date) completed_on_time_count,
       round(100.0*count(*) FILTER(WHERE status='COMPLETED' AND completed_date<=scheduled_date)/NULLIF(count(*),0),2) compliance_percent
FROM pm_executions GROUP BY 1 ORDER BY 1;

CREATE OR REPLACE VIEW v_emergency_work_monthly AS
SELECT date_trunc('month',requested_at)::date period,count(*) total_work_orders,
       count(*) FILTER(WHERE emergency) emergency_work_orders,
       round(100.0*count(*) FILTER(WHERE emergency)/NULLIF(count(*),0),2) emergency_percent
FROM work_orders GROUP BY 1 ORDER BY 1;

CREATE OR REPLACE VIEW v_mttr_monthly AS
SELECT date_trunc('month',requested_at)::date period,count(*) qualifying_repairs,
       round(avg(EXTRACT(epoch FROM(work_completed_at-work_started_at))/60.0),2) mttr_minutes
FROM work_orders WHERE work_type IN('CORRECTIVE','EMERGENCY') AND work_started_at IS NOT NULL AND work_completed_at IS NOT NULL
GROUP BY 1 ORDER BY 1;

CREATE OR REPLACE VIEW v_mtbf_monthly AS
WITH months AS (
 SELECT generate_series(DATE '2026-01-01',DATE '2026-08-01',interval '1 month')::date period
), failures AS (
 SELECT date_trunc('month',failure_time)::date period,count(*) FILTER(WHERE production_stopped) failure_count
 FROM failure_events GROUP BY 1
)
SELECT m.period,COALESCE(f.failure_count,0) failure_count,
       round((EXTRACT(day FROM(m.period+interval '1 month'-interval '1 day'))*16)/NULLIF(f.failure_count,0),2) mtbf_hours
FROM months m LEFT JOIN failures f USING(period) ORDER BY m.period;

CREATE OR REPLACE VIEW v_repeat_failures_monthly AS
SELECT date_trunc('month',failure_time)::date period,count(*) failure_count,
       count(*) FILTER(WHERE repeat_failure) repeat_failure_count
FROM failure_events GROUP BY 1 ORDER BY 1;

CREATE OR REPLACE VIEW v_work_order_closure_monthly AS
SELECT date_trunc('month',requested_at)::date period,count(*) work_order_count,count(*) FILTER(WHERE status='CLOSED') closed_count,
       round(100.0*count(*) FILTER(WHERE status='CLOSED')/NULLIF(count(*),0),2) closure_percent
FROM work_orders GROUP BY 1 ORDER BY 1;

CREATE OR REPLACE VIEW v_critical_spares_monthly AS
WITH months AS (
 SELECT generate_series(DATE '2026-01-01',DATE '2026-08-01',interval '1 month')::date period
), critical_parts AS (
 SELECT DISTINCT p.part_id,p.minimum_quantity FROM parts p JOIN asset_parts ap USING(part_id)
 WHERE p.critical_spare OR ap.critical_for_asset
), balances AS (
 SELECT m.period,cp.part_id,cp.minimum_quantity,
        COALESCE(sum(it.quantity) FILTER(WHERE it.transaction_at < m.period+interval '1 month'),0) balance
 FROM months m CROSS JOIN critical_parts cp LEFT JOIN inventory_transactions it USING(part_id)
 GROUP BY m.period,cp.part_id,cp.minimum_quantity
)
SELECT period,count(*) critical_part_count,count(*) FILTER(WHERE balance>=minimum_quantity) available_part_count,
       round(100.0*count(*) FILTER(WHERE balance>=minimum_quantity)/NULLIF(count(*),0),2) availability_percent
FROM balances GROUP BY period ORDER BY period;

CREATE OR REPLACE VIEW v_reactive_overtime_monthly AS
SELECT date_trunc('month',cost_date)::date period,
       sum(amount) FILTER(WHERE overtime_type='REACTIVE') reactive_overtime_cost,
       sum(amount) FILTER(WHERE overtime_type='PLANNED') planned_overtime_cost
FROM maintenance_costs WHERE cost_category='OVERTIME' GROUP BY 1 ORDER BY 1;

CREATE OR REPLACE VIEW v_maintenance_cost_monthly AS
SELECT date_trunc('month',cost_date)::date period,cost_category,round(sum(amount),2) amount
FROM maintenance_costs GROUP BY 1,2 ORDER BY 1,2;

CREATE OR REPLACE VIEW v_asset_failure_monthly AS
SELECT date_trunc('month',failure_time)::date period,a.asset_code,f.failure_mode,
       count(*) failure_count,count(*) FILTER(WHERE repeat_failure) repeat_failure_count
FROM failure_events f JOIN assets a USING(asset_id) GROUP BY 1,2,3 ORDER BY 1,2,3;

CREATE OR REPLACE VIEW v_condition_measurements AS
SELECT cm.measured_at AS time,a.asset_code,cm.measurement_type,cm.numeric_value,cm.unit,
       cm.warning_threshold,cm.alarm_threshold,cm.threshold_direction,
       CASE WHEN cm.warning_threshold IS NULL THEN 'NORMAL'
            WHEN cm.threshold_direction='HIGH' AND cm.numeric_value>=cm.alarm_threshold THEN 'ALARM'
            WHEN cm.threshold_direction='HIGH' AND cm.numeric_value>=cm.warning_threshold THEN 'WARNING'
            WHEN cm.threshold_direction='LOW' AND cm.numeric_value<=cm.alarm_threshold THEN 'ALARM'
            WHEN cm.threshold_direction='LOW' AND cm.numeric_value<=cm.warning_threshold THEN 'WARNING'
            ELSE 'NORMAL' END condition_status,
       cm.source,cm.notes
FROM condition_measurements cm JOIN assets a USING(asset_id);

CREATE OR REPLACE VIEW v_asset_reliability_summary AS
WITH line_scope AS (
 SELECT alr.asset_id,string_agg(l.name,', ' ORDER BY l.line_code) lines
 FROM asset_line_relationships alr JOIN production_lines l USING(line_id) GROUP BY alr.asset_id
), failures AS (
 SELECT asset_id,count(*) failure_count,count(*) FILTER(WHERE repeat_failure) repeat_failure_count FROM failure_events GROUP BY asset_id
), downtime AS (
 SELECT asset_id,count(*) event_count,sum(EXTRACT(epoch FROM(downtime_end-downtime_start))/60.0) downtime_minutes
 FROM downtime_events WHERE NOT planned GROUP BY asset_id
), open_work AS (
 SELECT asset_id,count(*) open_work_orders FROM work_orders WHERE status NOT IN('CLOSED','CANCELLED') GROUP BY asset_id
), pm_due AS (
 SELECT p.asset_id,count(*) FILTER(WHERE e.completed_date>e.scheduled_date) late_pm_count FROM pm_executions e JOIN pm_plans p USING(pm_plan_id) GROUP BY p.asset_id
)
SELECT a.asset_code,a.name asset_name,COALESCE(ls.lines,initcap(replace(a.scope::text,'_',' '))) line_scope,
       ac.criticality_class,COALESCE(f.failure_count,0) failures,COALESCE(f.repeat_failure_count,0) repeat_failures,
       COALESCE(d.event_count,0) downtime_events,round(COALESCE(d.downtime_minutes,0),2) downtime_minutes,
       round(100.0*(238*16*60-COALESCE(d.downtime_minutes,0))/(238*16*60),2) uptime_percent,
       COALESCE(ow.open_work_orders,0) open_work_orders,COALESCE(pd.late_pm_count,0) late_pm_count
FROM assets a LEFT JOIN line_scope ls USING(asset_id) JOIN asset_criticality ac USING(asset_id)
LEFT JOIN failures f USING(asset_id) LEFT JOIN downtime d USING(asset_id) LEFT JOIN open_work ow USING(asset_id) LEFT JOIN pm_due pd USING(asset_id);

CREATE OR REPLACE VIEW v_work_order_backlog AS
SELECT w.work_order_number,a.asset_code,w.work_type,w.priority,w.title,w.requested_at,w.status,w.planned,
       round(EXTRACT(epoch FROM(TIMESTAMPTZ '2026-08-27 00:00-05'-w.requested_at))/86400.0,1) age_days
FROM work_orders w LEFT JOIN assets a USING(asset_id) WHERE w.status NOT IN('CLOSED','CANCELLED');

CREATE OR REPLACE VIEW v_filler_201_rca_story AS
SELECT f.failure_time AS time,w.work_order_number,f.failure_mode,f.repeat_failure,
       round(EXTRACT(epoch FROM(d.downtime_end-d.downtime_start))/60.0,2) downtime_minutes,
       r.rca_number,r.completed_at rca_completed_at,r.root_cause
FROM failure_events f JOIN assets a USING(asset_id) JOIN work_orders w USING(work_order_id)
LEFT JOIN downtime_events d USING(work_order_id) LEFT JOIN rca_events r USING(work_order_id)
WHERE a.asset_code='FILLER-201' ORDER BY f.failure_time;

CREATE OR REPLACE VIEW v_pm_revision_history AS
SELECT a.asset_code,p.pm_code,r.revision_number,r.effective_from,r.effective_to,r.change_reason,
       t.sequence_number,t.task_description,rca.rca_number
FROM pm_plan_revisions r JOIN pm_plans p USING(pm_plan_id) JOIN assets a USING(asset_id)
JOIN pm_tasks t USING(pm_plan_id,revision_number) LEFT JOIN rca_events rca USING(rca_event_id)
ORDER BY a.asset_code,p.pm_code,r.revision_number,t.sequence_number;

CREATE OR REPLACE VIEW v_blender_shared_risk_history AS
SELECT d.downtime_start AS failure_time,d.downtime_end AS estimated_available_at,w.work_order_number,
       immediate.name current_impacted_line,future.name future_line_at_risk,
       immediate_impact.delay_minutes immediate_delay_minutes,future_impact.delay_minutes projected_future_delay_minutes,
       aps.scheduled_start future_slot_start,aps.production_order future_production_order
FROM downtime_events d JOIN assets a USING(asset_id) JOIN work_orders w USING(work_order_id)
JOIN downtime_affected_lines immediate_impact ON immediate_impact.downtime_event_id=d.downtime_event_id AND immediate_impact.impact_type='IMMEDIATE'
JOIN production_lines immediate ON immediate.line_id=immediate_impact.line_id
JOIN downtime_affected_lines future_impact ON future_impact.downtime_event_id=d.downtime_event_id AND future_impact.impact_type='FUTURE_RISK'
JOIN production_lines future ON future.line_id=future_impact.line_id
LEFT JOIN asset_production_schedule aps ON aps.asset_id=a.asset_id AND aps.line_id=future.line_id
 AND aps.scheduled_start>=d.downtime_start AND aps.scheduled_start<d.downtime_end
WHERE a.asset_code='BLENDER-001';

CREATE OR REPLACE VIEW v_shift_maintenance_coverage AS
SELECT s.name shift_name,s.function,s.start_time,s.end_time,
       count(e.employee_id) FILTER(WHERE e.department='MAINTENANCE' AND e.active) maintenance_technicians,
       string_agg((e.first_name||' '||e.last_name),', ') FILTER(WHERE e.department='MAINTENANCE' AND e.active) technicians
FROM shifts s LEFT JOIN employee_shift_assignments esa ON esa.shift_id=s.shift_id AND esa.is_primary AND esa.effective_to IS NULL
LEFT JOIN employees e USING(employee_id) GROUP BY s.shift_id,s.name,s.function,s.start_time,s.end_time ORDER BY s.start_time;

CREATE OR REPLACE VIEW v_technician_skill_coverage AS
SELECT sk.name skill,max(es.proficiency_level) FILTER(WHERE e.employee_number='E001') shift_a_level,
       max(es.proficiency_level) FILTER(WHERE e.employee_number='E002') shift_b_level,
       count(*) FILTER(WHERE es.proficiency_level>=3) independently_qualified,
       sk.critical_skill
FROM skills sk LEFT JOIN employee_skills es USING(skill_id) LEFT JOIN employees e USING(employee_id)
GROUP BY sk.skill_id,sk.name,sk.critical_skill ORDER BY sk.name;

CREATE OR REPLACE VIEW v_operational_risks AS
SELECT 'SANITATION' risk_type,a.asset_code,sf.priority::text severity,sf.description,
       sf.reported_at identified_at,'Startup risk unresolved' status
FROM sanitation_findings sf JOIN assets a USING(asset_id) WHERE sf.startup_risk AND sf.status NOT IN('RESOLVED','CLOSED')
UNION ALL
SELECT 'CONDITION',a.asset_code,'HIGH','Air compressor condition trend crossed warning threshold',max(cm.measured_at),'Planned predictive work completed; continue monitoring'
FROM condition_measurements cm JOIN assets a USING(asset_id) WHERE a.asset_code='AIR-COMP-001' GROUP BY a.asset_code
UNION ALL
SELECT 'WORK_ORDER',a.asset_code,w.priority::text,w.title,w.requested_at,w.status::text
FROM work_orders w JOIN assets a USING(asset_id) WHERE w.priority='CRITICAL' AND w.status NOT IN('CLOSED','CANCELLED');

COMMIT;
