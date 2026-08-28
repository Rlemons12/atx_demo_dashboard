\pset pager off
\echo '=== Connection and target ==='
SELECT current_database() AS database_name, current_schema() AS schema_name,
       current_setting('server_version') AS server_version, 'SUCCESS' AS connection_status;

DO $$
DECLARE missing_views text;
BEGIN
  IF current_database() <> 'atx_demo_dashboard' THEN RAISE EXCEPTION 'Wrong target database: %', current_database(); END IF;
  IF (SELECT count(*) FROM sites) <> 1 THEN RAISE EXCEPTION 'Expected 1 site'; END IF;
  IF (SELECT count(*) FROM production_lines) <> 2 THEN RAISE EXCEPTION 'Expected 2 production lines'; END IF;
  IF (SELECT count(*) FROM shifts) <> 3 THEN RAISE EXCEPTION 'Expected 3 shifts'; END IF;
  IF (SELECT count(*) FROM employees) <> 10 THEN RAISE EXCEPTION 'Expected 10 employees'; END IF;
  IF (SELECT count(*) FROM assets) <> 10 THEN RAISE EXCEPTION 'Expected 10 assets'; END IF;
  IF (SELECT count(*) FROM assets WHERE scope='DEDICATED_PRODUCTION') <> 8 THEN RAISE EXCEPTION 'Expected 8 dedicated assets'; END IF;
  IF (SELECT count(*) FROM assets WHERE scope='SHARED_PRODUCTION') <> 1 THEN RAISE EXCEPTION 'Expected 1 shared production asset'; END IF;
  IF (SELECT count(*) FROM assets WHERE scope='SHARED_UTILITY') <> 1 THEN RAISE EXCEPTION 'Expected 1 shared utility asset'; END IF;
  IF (SELECT count(*) FROM pm_plans WHERE active) <> 50 THEN RAISE EXCEPTION 'Expected exactly 50 active PM plans'; END IF;
  IF EXISTS (SELECT 1 FROM assets a CROSS JOIN unnest(enum_range(NULL::pm_frequency)) f
             WHERE NOT EXISTS (SELECT 1 FROM pm_plans p WHERE p.asset_id=a.asset_id AND p.frequency=f AND p.active))
    THEN RAISE EXCEPTION 'At least one asset is missing a PM frequency'; END IF;
  IF EXISTS (SELECT 1 FROM pm_plans p WHERE NOT EXISTS (SELECT 1 FROM pm_tasks t WHERE t.pm_plan_id=p.pm_plan_id AND t.revision_number=p.current_revision AND t.active))
    THEN RAISE EXCEPTION 'At least one PM plan has no active tasks'; END IF;
  IF EXISTS (SELECT 1 FROM assets a WHERE NOT EXISTS (SELECT 1 FROM asset_parts ap WHERE ap.asset_id=a.asset_id))
    THEN RAISE EXCEPTION 'At least one asset has no spare parts'; END IF;
  IF (SELECT count(*) FROM employees e JOIN employee_shift_assignments esa USING(employee_id) JOIN shifts s USING(shift_id)
      WHERE e.department='MAINTENANCE' AND s.shift_code='PROD-A' AND esa.is_primary AND esa.effective_to IS NULL) <> 1
    THEN RAISE EXCEPTION 'Production Shift A must have exactly one maintenance technician'; END IF;
  IF (SELECT count(*) FROM employees e JOIN employee_shift_assignments esa USING(employee_id) JOIN shifts s USING(shift_id)
      WHERE e.department='MAINTENANCE' AND s.shift_code='PROD-B' AND esa.is_primary AND esa.effective_to IS NULL) <> 1
    THEN RAISE EXCEPTION 'Production Shift B must have exactly one maintenance technician'; END IF;
  IF (SELECT count(*) FROM employees e JOIN employee_shift_assignments esa USING(employee_id) JOIN shifts s USING(shift_id)
      WHERE e.department='MAINTENANCE' AND s.shift_code='SAN' AND esa.is_primary AND esa.effective_to IS NULL) <> 0
    THEN RAISE EXCEPTION 'Sanitation must have no normal maintenance technician'; END IF;
  IF NOT EXISTS (SELECT 1 FROM asset_line_relationships r JOIN assets a USING(asset_id) JOIN production_lines l USING(line_id)
                 WHERE a.asset_code='AIR-COMP-001' AND l.line_code='LINE-1' AND r.relationship_type='SIMULTANEOUS_DEPENDENCY')
    THEN RAISE EXCEPTION 'Missing Air-Comp-001 Line 1 dependency'; END IF;
  IF NOT EXISTS (SELECT 1 FROM asset_line_relationships r JOIN assets a USING(asset_id) JOIN production_lines l USING(line_id)
                 WHERE a.asset_code='AIR-COMP-001' AND l.line_code='LINE-2' AND r.relationship_type='SIMULTANEOUS_DEPENDENCY')
    THEN RAISE EXCEPTION 'Missing Air-Comp-001 Line 2 dependency'; END IF;
  IF NOT EXISTS (SELECT 1 FROM asset_line_relationships r JOIN assets a USING(asset_id) JOIN production_lines l USING(line_id)
                 WHERE a.asset_code='BLENDER-001' AND l.line_code='LINE-1' AND r.relationship_type='SCHEDULED_SHARED')
    THEN RAISE EXCEPTION 'Missing Blender-001 Line 1 dependency'; END IF;
  IF NOT EXISTS (SELECT 1 FROM asset_line_relationships r JOIN assets a USING(asset_id) JOIN production_lines l USING(line_id)
                 WHERE a.asset_code='BLENDER-001' AND l.line_code='LINE-2' AND r.relationship_type='SCHEDULED_SHARED')
    THEN RAISE EXCEPTION 'Missing Blender-001 Line 2 dependency'; END IF;
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE contype IN ('f','c') AND connamespace='public'::regnamespace AND NOT convalidated)
    THEN RAISE EXCEPTION 'Unvalidated foreign key or check constraint exists'; END IF;
  SELECT string_agg(required.name, ', ') INTO missing_views
  FROM (VALUES ('v_plant_uptime'),('v_line_uptime'),('v_asset_uptime'),('v_pm_compliance'),
      ('v_emergency_work_percentage'),('v_mttr'),('v_mtbf'),('v_critical_response_time'),
      ('v_repeat_failures'),('v_work_order_closure_rate'),('v_critical_spare_availability'),
      ('v_downtime_by_asset'),('v_downtime_by_failure_mode'),('v_planned_vs_reactive_work'),
      ('v_planned_vs_reactive_overtime'),('v_open_critical_work_orders'),('v_overdue_pm'),
      ('v_open_rca_actions'),('v_sanitation_maintenance_risk'),('v_shared_asset_risk')) required(name)
  WHERE to_regclass('public.'||required.name) IS NULL;
  IF missing_views IS NOT NULL THEN RAISE EXCEPTION 'Missing views: %', missing_views; END IF;
END $$;

\echo '=== Master data counts ==='
SELECT (SELECT count(*) FROM sites) sites,
       (SELECT count(*) FROM production_lines) production_lines,
       (SELECT count(*) FROM shifts) shifts,
       (SELECT count(*) FROM employees) employees,
       (SELECT count(*) FROM assets) assets,
       (SELECT count(*) FROM asset_line_relationships) asset_line_relationships,
       (SELECT count(*) FROM pm_plans) pm_plans,
       (SELECT count(*) FROM pm_tasks) pm_tasks,
       (SELECT count(*) FROM parts) parts,
       (SELECT count(*) FROM asset_parts) asset_parts,
       (SELECT count(*) FROM skills) skills,
       (SELECT count(*) FROM employee_skills) employee_skills;

\echo '=== Asset scope ==='
SELECT scope, count(*) FROM assets GROUP BY scope ORDER BY scope;
\echo '=== Required shared dependencies ==='
SELECT a.asset_code,l.name AS line,r.relationship_type FROM asset_line_relationships r
JOIN assets a USING(asset_id) JOIN production_lines l USING(line_id)
WHERE a.asset_code IN ('AIR-COMP-001','BLENDER-001') ORDER BY a.asset_code,l.line_code;
\echo '=== PM frequency coverage ==='
SELECT frequency,count(*) FROM pm_plans WHERE active GROUP BY frequency ORDER BY frequency;
SELECT count(*) AS assets_missing_any_pm_frequency FROM assets a
WHERE (SELECT count(DISTINCT frequency) FROM pm_plans p WHERE p.asset_id=a.asset_id AND p.active) <> 5;
\echo '=== Spare parts coverage ==='
SELECT count(*) AS unique_parts,
       (SELECT count(*) FROM asset_parts) AS asset_part_relationships,
       (SELECT count(*) FROM assets a WHERE NOT EXISTS (SELECT 1 FROM asset_parts ap WHERE ap.asset_id=a.asset_id)) AS assets_without_spare_parts,
       count(*) FILTER(WHERE critical_spare) AS critical_spare_count FROM parts;
\echo '=== Shift maintenance coverage ==='
SELECT s.name,count(e.employee_id) FILTER(WHERE e.department='MAINTENANCE') AS maintenance_technicians
FROM shifts s LEFT JOIN employee_shift_assignments esa ON esa.shift_id=s.shift_id AND esa.is_primary AND esa.effective_to IS NULL
LEFT JOIN employees e ON e.employee_id=esa.employee_id AND e.active GROUP BY s.shift_id,s.name ORDER BY s.shift_id;
\echo '=== Constraint validation ==='
SELECT count(*) FILTER(WHERE contype='f') AS foreign_keys,
       count(*) FILTER(WHERE contype='c') AS check_constraints,
       count(*) FILTER(WHERE NOT convalidated) AS unvalidated_constraints
FROM pg_constraint WHERE connamespace='public'::regnamespace AND contype IN ('f','c');
\echo '=== Grafana view execution ==='
SELECT 'v_plant_uptime' view_name,count(*) rows,'SUCCESS' status FROM v_plant_uptime UNION ALL
SELECT 'v_line_uptime',count(*),'SUCCESS' FROM v_line_uptime UNION ALL
SELECT 'v_asset_uptime',count(*),'SUCCESS' FROM v_asset_uptime UNION ALL
SELECT 'v_pm_compliance',count(*),'SUCCESS' FROM v_pm_compliance UNION ALL
SELECT 'v_emergency_work_percentage',count(*),'SUCCESS' FROM v_emergency_work_percentage UNION ALL
SELECT 'v_mttr',count(*),'SUCCESS' FROM v_mttr UNION ALL
SELECT 'v_mtbf',count(*),'SUCCESS' FROM v_mtbf UNION ALL
SELECT 'v_critical_response_time',count(*),'SUCCESS' FROM v_critical_response_time UNION ALL
SELECT 'v_repeat_failures',count(*),'SUCCESS' FROM v_repeat_failures UNION ALL
SELECT 'v_work_order_closure_rate',count(*),'SUCCESS' FROM v_work_order_closure_rate UNION ALL
SELECT 'v_critical_spare_availability',count(*),'SUCCESS' FROM v_critical_spare_availability UNION ALL
SELECT 'v_downtime_by_asset',count(*),'SUCCESS' FROM v_downtime_by_asset UNION ALL
SELECT 'v_downtime_by_failure_mode',count(*),'SUCCESS' FROM v_downtime_by_failure_mode UNION ALL
SELECT 'v_planned_vs_reactive_work',count(*),'SUCCESS' FROM v_planned_vs_reactive_work UNION ALL
SELECT 'v_planned_vs_reactive_overtime',count(*),'SUCCESS' FROM v_planned_vs_reactive_overtime UNION ALL
SELECT 'v_open_critical_work_orders',count(*),'SUCCESS' FROM v_open_critical_work_orders UNION ALL
SELECT 'v_overdue_pm',count(*),'SUCCESS' FROM v_overdue_pm UNION ALL
SELECT 'v_open_rca_actions',count(*),'SUCCESS' FROM v_open_rca_actions UNION ALL
SELECT 'v_sanitation_maintenance_risk',count(*),'SUCCESS' FROM v_sanitation_maintenance_risk UNION ALL
SELECT 'v_shared_asset_risk',count(*),'SUCCESS' FROM v_shared_asset_risk ORDER BY 1;
\echo 'VALIDATION PASSED'
