\pset pager off
\echo '=== Milestone 2 record counts ==='
SELECT (SELECT count(*) FROM work_orders) work_orders,
       (SELECT count(*) FROM pm_executions) pm_executions,
       (SELECT count(*) FROM downtime_events) downtime_events,
       (SELECT count(*) FROM failure_events) failure_events,
       (SELECT count(*) FROM rca_events) rca_events,
       (SELECT count(*) FROM corrective_actions) corrective_actions,
       (SELECT count(*) FROM sanitation_findings) sanitation_findings,
       (SELECT count(*) FROM inventory_transactions) inventory_transactions,
       (SELECT count(*) FROM maintenance_costs) maintenance_costs,
       (SELECT count(*) FROM condition_measurements) condition_measurements;

DO $$
DECLARE early numeric; late numeric; missing_views text;
BEGIN
 IF (SELECT count(*) FROM work_orders)<180 THEN RAISE EXCEPTION 'Too few work orders'; END IF;
 IF (SELECT count(*) FROM pm_executions)<300 THEN RAISE EXCEPTION 'Too few PM executions'; END IF;
 IF (SELECT count(*) FROM downtime_events)<70 THEN RAISE EXCEPTION 'Too few downtime events'; END IF;
 IF (SELECT count(*) FROM failure_events)<60 THEN RAISE EXCEPTION 'Too few failure events'; END IF;
 IF (SELECT count(*) FROM rca_events)<10 THEN RAISE EXCEPTION 'Too few RCA events'; END IF;
 IF (SELECT count(*) FROM sanitation_findings)<30 THEN RAISE EXCEPTION 'Too few sanitation findings'; END IF;
 IF (SELECT count(*) FROM inventory_transactions WHERE reference<>'OPENING-BALANCE-2026')=0 THEN RAISE EXCEPTION 'No historical inventory movement'; END IF;
 IF (SELECT count(*) FROM maintenance_costs)=0 THEN RAISE EXCEPTION 'No maintenance costs'; END IF;
 IF (SELECT count(*) FROM condition_measurements cm JOIN assets a USING(asset_id) WHERE a.asset_code='AIR-COMP-001')=0 THEN RAISE EXCEPTION 'No compressor condition history'; END IF;
 IF (SELECT count(*) FROM asset_production_schedule aps JOIN assets a USING(asset_id) WHERE a.asset_code='BLENDER-001')<3 THEN RAISE EXCEPTION 'Missing Blender schedule'; END IF;
 IF (SELECT count(*) FROM failure_events f JOIN assets a USING(asset_id) WHERE a.asset_code='FILLER-201' AND repeat_failure)<4 THEN RAISE EXCEPTION 'Insufficient Filler-201 repeat history'; END IF;
 IF NOT EXISTS (SELECT 1 FROM rca_events r JOIN work_orders w USING(work_order_id) JOIN assets a USING(asset_id) WHERE a.asset_code='FILLER-201' AND root_cause ILIKE '%locking%') THEN RAISE EXCEPTION 'Missing Filler-201 RCA'; END IF;
 IF NOT EXISTS (SELECT 1 FROM pm_plan_revisions r JOIN pm_plans p USING(pm_plan_id) JOIN assets a USING(asset_id) WHERE a.asset_code='FILLER-201' AND p.frequency='WEEKLY' AND r.revision_number=2) THEN RAISE EXCEPTION 'Missing Filler-201 PM revision'; END IF;
 IF (SELECT count(*) FROM failure_events f JOIN assets a USING(asset_id) WHERE a.asset_code='CONVEYOR-201' AND repeat_failure)<3 THEN RAISE EXCEPTION 'Insufficient Conveyor-201 repeat history'; END IF;

 SELECT uptime_percent INTO early FROM v_plant_uptime_monthly ORDER BY period LIMIT 1;
 SELECT uptime_percent INTO late FROM v_plant_uptime_monthly ORDER BY period DESC LIMIT 1;
 IF late<=early THEN RAISE EXCEPTION 'Plant uptime did not improve: % to %',early,late; END IF;
 SELECT compliance_percent INTO early FROM v_pm_compliance_monthly ORDER BY period LIMIT 1;
 SELECT compliance_percent INTO late FROM v_pm_compliance_monthly ORDER BY period DESC LIMIT 1;
 IF late<=early THEN RAISE EXCEPTION 'PM compliance did not improve: % to %',early,late; END IF;
 SELECT emergency_percent INTO early FROM v_emergency_work_monthly ORDER BY period LIMIT 1;
 SELECT emergency_percent INTO late FROM v_emergency_work_monthly ORDER BY period DESC LIMIT 1;
 IF late>=early THEN RAISE EXCEPTION 'Emergency work did not decline: % to %',early,late; END IF;
 SELECT mttr_minutes INTO early FROM v_mttr_monthly ORDER BY period LIMIT 1;
 SELECT mttr_minutes INTO late FROM v_mttr_monthly ORDER BY period DESC LIMIT 1;
 IF late>=early THEN RAISE EXCEPTION 'MTTR did not improve: % to %',early,late; END IF;
 SELECT mtbf_hours INTO early FROM v_mtbf_monthly ORDER BY period LIMIT 1;
 SELECT mtbf_hours INTO late FROM v_mtbf_monthly ORDER BY period DESC LIMIT 1;
 IF late<=early THEN RAISE EXCEPTION 'MTBF did not improve: % to %',early,late; END IF;
 SELECT availability_percent INTO early FROM v_critical_spares_monthly ORDER BY period LIMIT 1;
 SELECT availability_percent INTO late FROM v_critical_spares_monthly ORDER BY period DESC LIMIT 1;
 IF late<early THEN RAISE EXCEPTION 'Critical-spare availability declined: % to %',early,late; END IF;
 SELECT repeat_failure_count INTO early FROM v_repeat_failures_monthly ORDER BY period LIMIT 1;
 SELECT repeat_failure_count INTO late FROM v_repeat_failures_monthly ORDER BY period DESC LIMIT 1;
 IF late>=early THEN RAISE EXCEPTION 'Repeat failures did not decline: % to %',early,late; END IF;
 SELECT reactive_overtime_cost INTO early FROM v_reactive_overtime_monthly ORDER BY period LIMIT 1;
 SELECT reactive_overtime_cost INTO late FROM v_reactive_overtime_monthly ORDER BY period DESC LIMIT 1;
 IF late>=early THEN RAISE EXCEPTION 'Reactive overtime did not decline: % to %',early,late; END IF;

 SELECT string_agg(name,', ') INTO missing_views FROM (VALUES
  ('v_plant_uptime_monthly'),('v_line_uptime_monthly'),('v_pm_compliance_weekly'),('v_pm_compliance_monthly'),
  ('v_emergency_work_monthly'),('v_mttr_monthly'),('v_mtbf_monthly'),('v_repeat_failures_monthly'),
  ('v_work_order_closure_monthly'),('v_critical_spares_monthly'),('v_reactive_overtime_monthly'),
  ('v_maintenance_cost_monthly'),('v_asset_failure_monthly'),('v_condition_measurements'),
  ('v_asset_reliability_summary'),('v_work_order_backlog'),('v_filler_201_rca_story'),
  ('v_pm_revision_history'),('v_blender_shared_risk_history'),('v_shift_maintenance_coverage'),
  ('v_technician_skill_coverage'),('v_operational_risks')) required(name)
 WHERE to_regclass('public.'||name) IS NULL;
 IF missing_views IS NOT NULL THEN RAISE EXCEPTION 'Missing Milestone 2 views: %',missing_views; END IF;
END $$;

\echo '=== KPI improvement: baseline versus current ==='
WITH metrics AS (
 SELECT 'Plant uptime (%)' metric,(SELECT uptime_percent FROM v_plant_uptime_monthly ORDER BY period LIMIT 1) baseline,
        (SELECT uptime_percent FROM v_plant_uptime_monthly ORDER BY period DESC LIMIT 1) current
 UNION ALL SELECT 'PM compliance (%)',(SELECT compliance_percent FROM v_pm_compliance_monthly ORDER BY period LIMIT 1),(SELECT compliance_percent FROM v_pm_compliance_monthly ORDER BY period DESC LIMIT 1)
 UNION ALL SELECT 'Emergency work (%)',(SELECT emergency_percent FROM v_emergency_work_monthly ORDER BY period LIMIT 1),(SELECT emergency_percent FROM v_emergency_work_monthly ORDER BY period DESC LIMIT 1)
 UNION ALL SELECT 'MTTR (minutes)',(SELECT mttr_minutes FROM v_mttr_monthly ORDER BY period LIMIT 1),(SELECT mttr_minutes FROM v_mttr_monthly ORDER BY period DESC LIMIT 1)
 UNION ALL SELECT 'MTBF (hours)',(SELECT mtbf_hours FROM v_mtbf_monthly ORDER BY period LIMIT 1),(SELECT mtbf_hours FROM v_mtbf_monthly ORDER BY period DESC LIMIT 1)
 UNION ALL SELECT 'Critical spares (%)',(SELECT availability_percent FROM v_critical_spares_monthly ORDER BY period LIMIT 1),(SELECT availability_percent FROM v_critical_spares_monthly ORDER BY period DESC LIMIT 1)
 UNION ALL SELECT 'Repeat failures',(SELECT repeat_failure_count FROM v_repeat_failures_monthly ORDER BY period LIMIT 1),(SELECT repeat_failure_count FROM v_repeat_failures_monthly ORDER BY period DESC LIMIT 1)
 UNION ALL SELECT 'WO closure (%)',(SELECT closure_percent FROM v_work_order_closure_monthly ORDER BY period LIMIT 1),(SELECT closure_percent FROM v_work_order_closure_monthly ORDER BY period DESC LIMIT 1)
 UNION ALL SELECT 'Reactive overtime ($)',(SELECT reactive_overtime_cost FROM v_reactive_overtime_monthly ORDER BY period LIMIT 1),(SELECT reactive_overtime_cost FROM v_reactive_overtime_monthly ORDER BY period DESC LIMIT 1)
)
SELECT * FROM metrics;

\echo '=== Scenario evidence ==='
SELECT 'Filler-201 repeat failures' scenario,count(*) value FROM failure_events f JOIN assets a USING(asset_id) WHERE a.asset_code='FILLER-201' AND repeat_failure
UNION ALL SELECT 'Conveyor-201 repeat failures',count(*) FROM failure_events f JOIN assets a USING(asset_id) WHERE a.asset_code='CONVEYOR-201' AND repeat_failure
UNION ALL SELECT 'Blender risk events',count(*) FROM v_blender_shared_risk_history
UNION ALL SELECT 'Air compressor condition readings',count(*) FROM v_condition_measurements WHERE asset_code='AIR-COMP-001';

\echo '=== Milestone 2 view execution ==='
SELECT 'v_plant_uptime_monthly' view_name,count(*) rows FROM v_plant_uptime_monthly UNION ALL
SELECT 'v_line_uptime_monthly',count(*) FROM v_line_uptime_monthly UNION ALL
SELECT 'v_pm_compliance_weekly',count(*) FROM v_pm_compliance_weekly UNION ALL
SELECT 'v_pm_compliance_monthly',count(*) FROM v_pm_compliance_monthly UNION ALL
SELECT 'v_emergency_work_monthly',count(*) FROM v_emergency_work_monthly UNION ALL
SELECT 'v_mttr_monthly',count(*) FROM v_mttr_monthly UNION ALL
SELECT 'v_mtbf_monthly',count(*) FROM v_mtbf_monthly UNION ALL
SELECT 'v_repeat_failures_monthly',count(*) FROM v_repeat_failures_monthly UNION ALL
SELECT 'v_work_order_closure_monthly',count(*) FROM v_work_order_closure_monthly UNION ALL
SELECT 'v_critical_spares_monthly',count(*) FROM v_critical_spares_monthly UNION ALL
SELECT 'v_reactive_overtime_monthly',count(*) FROM v_reactive_overtime_monthly UNION ALL
SELECT 'v_maintenance_cost_monthly',count(*) FROM v_maintenance_cost_monthly UNION ALL
SELECT 'v_asset_failure_monthly',count(*) FROM v_asset_failure_monthly UNION ALL
SELECT 'v_condition_measurements',count(*) FROM v_condition_measurements UNION ALL
SELECT 'v_asset_reliability_summary',count(*) FROM v_asset_reliability_summary UNION ALL
SELECT 'v_work_order_backlog',count(*) FROM v_work_order_backlog UNION ALL
SELECT 'v_filler_201_rca_story',count(*) FROM v_filler_201_rca_story UNION ALL
SELECT 'v_pm_revision_history',count(*) FROM v_pm_revision_history UNION ALL
SELECT 'v_blender_shared_risk_history',count(*) FROM v_blender_shared_risk_history UNION ALL
SELECT 'v_shift_maintenance_coverage',count(*) FROM v_shift_maintenance_coverage UNION ALL
SELECT 'v_technician_skill_coverage',count(*) FROM v_technician_skill_coverage UNION ALL
SELECT 'v_operational_risks',count(*) FROM v_operational_risks ORDER BY 1;
\echo 'MILESTONE 2 VALIDATION PASSED'
