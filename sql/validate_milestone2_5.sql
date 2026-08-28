\pset pager off
\echo '=== Milestone 2.5 record counts ==='
SELECT (SELECT count(*) FROM products) products,
       (SELECT count(*) FROM product_line_standards) product_line_standards,
       (SELECT count(*) FROM production_calendar) production_calendar_rows,
       (SELECT count(*) FROM production_lots) production_lots,
       (SELECT count(*) FROM production_lot_events) production_lot_events,
       (SELECT count(*) FROM production_schedule) production_schedule_rows,
       (SELECT count(*) FROM production_lot_assets) production_lot_assets,
       (SELECT count(*) FROM employee_schedules) employee_schedules,
       (SELECT count(*) FROM equipment_production_runs) equipment_production_runs;

DO $$
DECLARE
    missing_views text;
    l1_oee numeric;
    l2_oee numeric;
    f201_pre_oee numeric;
    f201_post_oee numeric;
    f201_pre_avail numeric;
    f201_post_avail numeric;
BEGIN
    -- 1. Entity count validations
    IF (SELECT count(*) FROM products) < 5 THEN
        RAISE EXCEPTION 'Too few products';
    END IF;

    IF (SELECT count(*) FROM product_line_standards) < 10 THEN
        RAISE EXCEPTION 'Missing product line standards';
    END IF;

    IF (SELECT count(*) FROM production_lots) < 500 THEN
        RAISE EXCEPTION 'Too few production lots';
    END IF;

    IF (SELECT count(*) FROM production_schedule) < 500 THEN
        RAISE EXCEPTION 'Too few production schedule entries';
    END IF;

    IF (SELECT count(*) FROM employee_schedules) < 1500 THEN
        RAISE EXCEPTION 'Too few employee schedules';
    END IF;

    IF (SELECT count(*) FROM equipment_production_runs) < 2500 THEN
        RAISE EXCEPTION 'Too few equipment production runs';
    END IF;

    -- 2. Staffing model validation (1/1/0 rule)
    IF (SELECT count(DISTINCT es.employee_id) FROM employee_schedules es
        JOIN shifts s USING(shift_id) WHERE s.shift_code = 'PROD-A' AND es.assigned_role = 'Maintenance Technician' AND es.schedule_date = DATE '2026-08-27') <> 1 THEN
        RAISE EXCEPTION 'Shift A maintenance coverage is not exactly 1 technician';
    END IF;

    IF (SELECT count(DISTINCT es.employee_id) FROM employee_schedules es
        JOIN shifts s USING(shift_id) WHERE s.shift_code = 'PROD-B' AND es.assigned_role = 'Maintenance Technician' AND es.schedule_date = DATE '2026-08-27') <> 1 THEN
        RAISE EXCEPTION 'Shift B maintenance coverage is not exactly 1 technician';
    END IF;

    IF (SELECT count(DISTINCT es.employee_id) FROM employee_schedules es
        JOIN shifts s USING(shift_id) WHERE s.shift_code = 'SAN' AND es.assigned_role = 'Maintenance Technician' AND es.schedule_date = DATE '2026-08-27') <> 0 THEN
        RAISE EXCEPTION 'Sanitation shift must have 0 regular maintenance technicians';
    END IF;

    -- 3. Production Count Integrity
    IF EXISTS (SELECT 1 FROM production_lots WHERE good_quantity + reject_quantity > total_quantity AND total_quantity > 0) THEN
        RAISE EXCEPTION 'Invalid lot counts: good + reject > total';
    END IF;

    IF EXISTS (SELECT 1 FROM equipment_production_runs WHERE good_count + reject_count > total_count AND total_count > 0) THEN
        RAISE EXCEPTION 'Invalid equipment run counts: good + reject > total';
    END IF;

    -- 4. Shared Blender Schedule Conflict Check
    IF EXISTS (
        SELECT 1
        FROM production_lot_assets a1
        JOIN assets ast ON ast.asset_id = a1.asset_id
        JOIN production_lot_assets a2 ON a2.asset_id = a1.asset_id AND a1.lot_id <> a2.lot_id
        WHERE ast.asset_code = 'BLENDER-001'
          AND a1.planned_start < a2.planned_end
          AND a1.planned_end > a2.planned_start
    ) THEN
        RAISE EXCEPTION 'Detected overlapping schedule for shared Blender-001';
    END IF;

    -- 5. View existence validation
    SELECT string_agg(name, ', ') INTO missing_views
    FROM (VALUES
        ('v_current_production_lots'),
        ('v_upcoming_production_lots'),
        ('v_completed_production_lots'),
        ('v_production_schedule_adherence'),
        ('v_employee_schedule_current'),
        ('v_employee_schedule_daily'),
        ('v_shift_staffing_coverage'),
        ('v_asset_oee_daily'),
        ('v_asset_oee_weekly'),
        ('v_asset_oee_monthly'),
        ('v_line_oee_daily'),
        ('v_line_oee_weekly'),
        ('v_line_oee_monthly'),
        ('v_asset_oee_components'),
        ('v_line_oee_components'),
        ('v_oee_loss_by_category'),
        ('v_filler201_oee_before_after_rca')
    ) required(name)
    WHERE to_regclass('public.' || name) IS NULL;

    IF missing_views IS NOT NULL THEN
        RAISE EXCEPTION 'Missing Milestone 2.5 views: %', missing_views;
    END IF;

    -- 6. OEE Narrative & Trend Validation
    SELECT oee_percent INTO l1_oee FROM v_line_oee_monthly WHERE line_code = 'LINE-1' AND period = DATE '2026-08-01';
    SELECT oee_percent INTO l2_oee FROM v_line_oee_monthly WHERE line_code = 'LINE-2' AND period = DATE '2026-08-01';

    IF l1_oee IS NULL OR l2_oee IS NULL OR l1_oee <= l2_oee THEN
        RAISE EXCEPTION 'Line 1 August OEE (%) must exceed Line 2 August OEE (%)', l1_oee, l2_oee;
    END IF;

    -- Filler-201 Pre vs Post RCA improvement
    SELECT oee_percent, availability_percent INTO f201_pre_oee, f201_pre_avail
    FROM v_filler201_oee_before_after_rca WHERE rca_period LIKE 'PRE_RCA%';

    SELECT oee_percent, availability_percent INTO f201_post_oee, f201_post_avail
    FROM v_filler201_oee_before_after_rca WHERE rca_period LIKE 'POST_RCA%';

    IF f201_post_oee <= f201_pre_oee THEN
        RAISE EXCEPTION 'Filler-201 OEE did not improve post-RCA: pre=% post=%', f201_pre_oee, f201_post_oee;
    END IF;

    IF f201_post_avail <= f201_pre_avail THEN
        RAISE EXCEPTION 'Filler-201 Availability did not improve post-RCA: pre=% post=%', f201_pre_avail, f201_post_avail;
    END IF;
END $$;

\echo '=== Current Lots Running (Aug 27, 2026 19:13 Snapshot) ==='
SELECT line_code, lot_number, product_code, product_name, status, actual_start, planned_quantity, total_quantity, good_quantity, progress_percent, yield_percent
FROM v_current_production_lots;

\echo '=== Upcoming Lots (Next in Queue) ==='
SELECT line_code, lot_number, product_code, scheduled_start, sequence_number, status
FROM v_upcoming_production_lots
LIMIT 4;

\echo '=== Active Shift Employee Coverage (2026-08-27 Shift B) ==='
SELECT employee_number, employee_name, job_title, department, assigned_role, line_assignment, shift_code, status
FROM v_employee_schedule_current;

\echo '=== Shift Staffing Coverage Matrix (1/1/0 Rule Check) ==='
SELECT * FROM v_shift_staffing_coverage;

\echo '=== Line OEE Monthly Comparison ==='
SELECT period, line_code, availability_percent, performance_percent, quality_percent, oee_percent
FROM v_line_oee_monthly
WHERE period IN (DATE '2026-01-01', DATE '2026-08-01')
ORDER BY period, line_code;

\echo '=== Filler-201 OEE Pre vs Post RCA Story ==='
SELECT * FROM v_filler201_oee_before_after_rca;

\echo '=== View Row Counts ==='
SELECT 'v_current_production_lots' view_name, count(*) rows FROM v_current_production_lots UNION ALL
SELECT 'v_upcoming_production_lots', count(*) FROM v_upcoming_production_lots UNION ALL
SELECT 'v_completed_production_lots', count(*) FROM v_completed_production_lots UNION ALL
SELECT 'v_production_schedule_adherence', count(*) FROM v_production_schedule_adherence UNION ALL
SELECT 'v_employee_schedule_current', count(*) FROM v_employee_schedule_current UNION ALL
SELECT 'v_employee_schedule_daily', count(*) FROM v_employee_schedule_daily UNION ALL
SELECT 'v_shift_staffing_coverage', count(*) FROM v_shift_staffing_coverage UNION ALL
SELECT 'v_asset_oee_daily', count(*) FROM v_asset_oee_daily UNION ALL
SELECT 'v_asset_oee_weekly', count(*) FROM v_asset_oee_weekly UNION ALL
SELECT 'v_asset_oee_monthly', count(*) FROM v_asset_oee_monthly UNION ALL
SELECT 'v_line_oee_daily', count(*) FROM v_line_oee_daily UNION ALL
SELECT 'v_line_oee_weekly', count(*) FROM v_line_oee_weekly UNION ALL
SELECT 'v_line_oee_monthly', count(*) FROM v_line_oee_monthly UNION ALL
SELECT 'v_asset_oee_components', count(*) FROM v_asset_oee_components UNION ALL
SELECT 'v_line_oee_components', count(*) FROM v_line_oee_components UNION ALL
SELECT 'v_oee_loss_by_category', count(*) FROM v_oee_loss_by_category UNION ALL
SELECT 'v_filler201_oee_before_after_rca', count(*) FROM v_filler201_oee_before_after_rca
ORDER BY 1;

\echo 'MILESTONE 2.5 VALIDATION PASSED'
