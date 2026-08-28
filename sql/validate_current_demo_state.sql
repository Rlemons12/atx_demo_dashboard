\echo 'Validating fixed current demo operating state...'

DO $$
DECLARE
    anchor timestamptz;
BEGIN
    IF (SELECT count(*) FROM demo_context WHERE active) <> 1 THEN
        RAISE EXCEPTION 'Expected exactly one active demo context';
    END IF;

    SELECT anchor_timestamp INTO anchor FROM v_demo_context_active;
    IF anchor <> TIMESTAMPTZ '2026-08-28 10:00:00-05' THEN
        RAISE EXCEPTION 'Unexpected demo anchor: %', anchor;
    END IF;

    IF (SELECT count(*) FROM v_current_line1_production_status) <> 1 THEN
        RAISE EXCEPTION 'Line 1 must have exactly one active lot at the demo anchor';
    END IF;
    IF (SELECT count(*) FROM v_current_line2_production_status) <> 1 THEN
        RAISE EXCEPTION 'Line 2 must have exactly one active lot at the demo anchor';
    END IF;
    IF EXISTS (
        SELECT 1 FROM v_current_production_status
        WHERE anchor_timestamp < scheduled_start OR anchor_timestamp >= scheduled_end
           OR status <> 'RUNNING' OR schedule_status <> 'IN_PROGRESS'
           OR good_quantity + reject_quantity > total_quantity
           OR total_quantity > planned_quantity
           OR actual_start > anchor_timestamp
           OR current_rate <= 0
    ) THEN
        RAISE EXCEPTION 'Current production timing, status, count, or rate integrity failed';
    END IF;

    IF (SELECT count(DISTINCT a.asset_code)
        FROM v_current_line2_production_status c
        JOIN production_lot_assets pla ON pla.lot_id = c.lot_id
        JOIN assets a ON a.asset_id = pla.asset_id
        WHERE a.asset_code IN ('MIXER-201','CONVEYOR-201','FILLER-201','LABELER-201')) <> 4 THEN
        RAISE EXCEPTION 'Current Line 2 lot is not linked to all four dedicated assets';
    END IF;

    IF (SELECT count(*) FROM v_current_equipment_state) <> 4 THEN
        RAISE EXCEPTION 'Expected current state for all four Line 2 assets';
    END IF;
    IF EXISTS (SELECT 1 FROM v_current_equipment_state WHERE lot_number <> 'ATX-20260828-L2-001' OR shift_code <> 'PROD-A') THEN
        RAISE EXCEPTION 'Current Line 2 equipment context mismatch';
    END IF;
    IF (SELECT count(DISTINCT asset_code) FROM v_current_sensor_state) <> 4 THEN
        RAISE EXCEPTION 'Expected current sensor data for all four Line 2 assets';
    END IF;
    IF EXISTS (
        SELECT 1 FROM v_current_sensor_state
        WHERE asset_code = 'FILLER-201'
          AND observed_at < anchor_timestamp - INTERVAL '5 minutes'
    ) THEN
        RAISE EXCEPTION 'Filler-201 current sensor data is stale relative to the anchor';
    END IF;
    IF (SELECT count(*) FROM v_current_shift_staffing) <> 4 THEN
        RAISE EXCEPTION 'Expected four-person Shift A current staffing roster';
    END IF;
    IF EXISTS (SELECT 1 FROM v_current_shift_staffing WHERE shift_code <> 'PROD-A' OR status <> 'CONFIRMED') THEN
        RAISE EXCEPTION 'Current staffing did not resolve to confirmed Production Shift A';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM v_current_month_schedule_adherence WHERE period = DATE '2026-08-01') THEN
        RAISE EXCEPTION 'Schedule adherence did not resolve August 2026 from demo anchor';
    END IF;
    IF EXISTS (
        SELECT 1 FROM v_current_equipment_state
        WHERE asset_code = 'AIR-COMP-001'
    ) OR EXISTS (
        SELECT 1 FROM v_equipment_oee_summary WHERE asset_code = 'AIR-COMP-001'
    ) THEN
        RAISE EXCEPTION 'Air-Comp-001 must remain outside current piece-rate OEE';
    END IF;
END $$;

SELECT context_name, anchor_timestamp, description FROM v_demo_context_active;
SELECT line_code, lot_number, product_name, shift_code, scheduled_start, scheduled_end,
       planned_quantity, total_quantity, good_quantity, reject_quantity,
       progress_percent, yield_percent, current_rate, status, schedule_status
FROM v_current_production_status ORDER BY line_code;
SELECT employee_number, employee_name, assigned_role, line_assignment, shift_code, status
FROM v_current_shift_staffing;
SELECT asset_code, state_code, run_status, COALESCE(current_fault, 'None') current_fault,
       lot_number, product_name, shift_code, most_recent_state_timestamp
FROM v_current_equipment_state ORDER BY asset_code;
SELECT asset_code, count(*) sensor_count, max(observed_at) latest_observed_at
FROM v_current_sensor_state GROUP BY asset_code ORDER BY asset_code;
SELECT period, line_code, scheduled_lots, on_time_start_percent
FROM v_current_month_schedule_adherence ORDER BY line_code;

\echo 'CURRENT DEMO STATE VALIDATION PASSED'
