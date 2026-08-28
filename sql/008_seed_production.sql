BEGIN;

-- Fixed demonstration period: 2026-01-01 through 2026-08-28.
-- Guard against multiple runs without rebuild
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM products) THEN
        RAISE EXCEPTION 'Milestone 2.5 production data already exists; use the guarded rebuild process.';
    END IF;
END $$;

-- 1. Product Master (5 fictional SKUs)
INSERT INTO products (product_code, product_name, description, default_batch_size, units_per_case)
VALUES
('ATX-1001', 'Classic Sauce', 'Signature mild tomato & herb sauce', 500.00, 12),
('ATX-1002', 'Spicy Sauce', 'Habanero and cayenne infused spicy sauce', 500.00, 12),
('ATX-1003', 'Garlic Sauce', 'Roasted garlic savory sauce', 500.00, 12),
('ATX-2001', 'BBQ Blend', 'Smoky chipotle barbecue sauce', 600.00, 12),
('ATX-2002', 'Sweet Heat', 'Honey chili glazed finishing sauce', 500.00, 12);

-- 2. Product-Line Performance Standards (10 standards: 5 products x 2 lines)
INSERT INTO product_line_standards (product_id, line_id, ideal_units_per_minute, expected_yield_pct, standard_changeover_minutes)
SELECT p.product_id, l.line_id, v.ideal_upm, v.yield_pct, v.changeover_mins
FROM (VALUES
    ('ATX-1001', 'LINE-1', 140.00, 99.00, 25),
    ('ATX-1002', 'LINE-1', 120.00, 98.50, 35),
    ('ATX-1003', 'LINE-1', 130.00, 98.80, 30),
    ('ATX-2001', 'LINE-1', 125.00, 98.50, 30),
    ('ATX-2002', 'LINE-1', 135.00, 98.70, 30),
    ('ATX-1001', 'LINE-2', 120.00, 98.50, 30),
    ('ATX-1002', 'LINE-2', 105.00, 98.00, 40),
    ('ATX-1003', 'LINE-2', 115.00, 98.30, 35),
    ('ATX-2001', 'LINE-2', 110.00, 98.20, 35),
    ('ATX-2002', 'LINE-2', 115.00, 98.40, 35)
) AS v(product_code, line_code, ideal_upm, yield_pct, changeover_mins)
JOIN products p USING (product_code)
JOIN production_lines l USING (line_code);

-- 3. Production Calendar (Workdays Monday-Friday, Jan 1 to Aug 28, 2026)
WITH calendar_days AS (
    SELECT d::date AS prod_date
    FROM generate_series(DATE '2026-01-01', DATE '2026-08-28', interval '1 day') d
    WHERE EXTRACT(ISODOW FROM d) BETWEEN 1 AND 5
)
INSERT INTO production_calendar (
    production_date, shift_id, line_id, scheduled_minutes, planned_break_minutes, planned_changeover_minutes, planned_production_minutes
)
SELECT cd.prod_date, s.shift_id, l.line_id, 480, 30, 30, 420
FROM calendar_days cd
CROSS JOIN shifts s
CROSS JOIN production_lines l
WHERE s.shift_code IN ('PROD-A', 'PROD-B');

-- 4. Employee Schedules (Jan 1 to Aug 28, 2026)
-- Conforms strictly to 1 tech / shift on PROD-A, 1 on PROD-B, 0 on SAN
WITH calendar_days AS (
    SELECT d::date AS sched_date
    FROM generate_series(DATE '2026-01-01', DATE '2026-08-28', interval '1 day') d
    WHERE EXTRACT(ISODOW FROM d) BETWEEN 1 AND 5
),
staff_patterns AS (
    SELECT * FROM (VALUES
        -- Shift A (06:00 - 14:00)
        ('PROD-A', 'E005', 'Production Lead', NULL::text, '06:00'::time, '14:00'::time, NULL::overtime_type),
        ('PROD-A', 'E003', 'Line 1 Operator', 'LINE-1', '06:00'::time, '14:00'::time, NULL::overtime_type),
        ('PROD-A', 'E004', 'Line 2 Operator', 'LINE-2', '06:00'::time, '14:00'::time, NULL::overtime_type),
        ('PROD-A', 'E001', 'Maintenance Technician', NULL::text, '06:00'::time, '14:00'::time, NULL::overtime_type),
        -- Shift B (14:00 - 22:00)
        ('PROD-B', 'E008', 'Production Lead', NULL::text, '14:00'::time, '22:00'::time, NULL::overtime_type),
        ('PROD-B', 'E006', 'Line 1 Operator', 'LINE-1', '14:00'::time, '22:00'::time, NULL::overtime_type),
        ('PROD-B', 'E007', 'Line 2 Operator', 'LINE-2', '14:00'::time, '22:00'::time, NULL::overtime_type),
        ('PROD-B', 'E002', 'Maintenance Technician', NULL::text, '14:00'::time, '22:00'::time, NULL::overtime_type),
        -- Sanitation Shift (22:00 - 06:00 next day) - No normal maintenance tech!
        ('SAN', 'E009', 'Sanitation Lead', NULL::text, '22:00'::time, '06:00'::time, NULL::overtime_type),
        ('SAN', 'E010', 'Sanitation Technician', NULL::text, '22:00'::time, '06:00'::time, NULL::overtime_type)
    ) AS v(shift_code, employee_number, assigned_role, line_code, start_t, end_t, ot_type)
)
INSERT INTO employee_schedules (
    employee_id, schedule_date, shift_id, line_id, scheduled_start, scheduled_end, assigned_role, overtime_type, status
)
SELECT
    e.employee_id,
    cd.sched_date,
    s.shift_id,
    l.line_id,
    (cd.sched_date + sp.start_t)::timestamptz AT TIME ZONE 'America/Chicago',
    (cd.sched_date + CASE WHEN sp.shift_code = 'SAN' THEN interval '1 day' ELSE interval '0 day' END + sp.end_t)::timestamptz AT TIME ZONE 'America/Chicago',
    sp.assigned_role,
    sp.ot_type,
    CASE
        WHEN cd.sched_date < DATE '2026-08-27' THEN 'COMPLETED'
        WHEN cd.sched_date = DATE '2026-08-27' THEN
            CASE sp.shift_code
                WHEN 'PROD-A' THEN 'COMPLETED'
                WHEN 'PROD-B' THEN 'CONFIRMED'
                ELSE 'SCHEDULED'
            END
        ELSE 'SCHEDULED'
    END
FROM calendar_days cd
CROSS JOIN staff_patterns sp
JOIN employees e ON e.employee_number = sp.employee_number
JOIN shifts s ON s.shift_code = sp.shift_code
LEFT JOIN production_lines l ON l.line_code = sp.line_code;

-- 5. Production Lots & Schedule Generation (Jan 1 to Aug 28, 2026)
-- 2 Lots per line per day:
-- Lot 1: Shift A (06:00 - 13:30)
-- Lot 2: Shift B (14:00 - 21:30)
DO $$
DECLARE
    r RECORD;
    v_lot_id bigint;
    v_prod RECORD;
    v_std RECORD;
    v_status text;
    v_actual_start timestamptz;
    v_actual_end timestamptz;
    v_planned_qty numeric(12,2);
    v_total_qty numeric(12,2);
    v_good_qty numeric(12,2);
    v_reject_qty numeric(12,2);
    v_runtime numeric(10,2);
    v_month int;
    v_day int;
    v_is_l1 boolean;
    v_filler_down numeric(10,2);
    v_conv_down numeric(10,2);
    v_prod_cursor int := 0;
    v_prod_ids bigint[];
    v_seq int := 1;
BEGIN
    SELECT array_agg(product_id ORDER BY product_code) INTO v_prod_ids FROM products;

    FOR r IN (
        SELECT
            cd.prod_date,
            s.shift_id,
            s.shift_code,
            l.line_id,
            l.line_code,
            CASE s.shift_code WHEN 'PROD-A' THEN 1 ELSE 2 END AS shift_seq,
            CASE s.shift_code
                WHEN 'PROD-A' THEN (cd.prod_date + interval '6 hours')::timestamptz AT TIME ZONE 'America/Chicago'
                ELSE (cd.prod_date + interval '14 hours')::timestamptz AT TIME ZONE 'America/Chicago'
            END AS plan_start,
            CASE s.shift_code
                WHEN 'PROD-A' THEN (cd.prod_date + interval '13 hours 30 minutes')::timestamptz AT TIME ZONE 'America/Chicago'
                ELSE (cd.prod_date + interval '21 hours 30 minutes')::timestamptz AT TIME ZONE 'America/Chicago'
            END AS plan_end
        FROM (
            SELECT d::date AS prod_date
            FROM generate_series(DATE '2026-01-01', DATE '2026-08-28', interval '1 day') d
            WHERE EXTRACT(ISODOW FROM d) BETWEEN 1 AND 5
        ) cd
        CROSS JOIN shifts s
        CROSS JOIN production_lines l
        WHERE s.shift_code IN ('PROD-A', 'PROD-B')
        ORDER BY cd.prod_date, s.shift_code, l.line_code
    ) LOOP
        v_month := EXTRACT(MONTH FROM r.prod_date);
        v_day := EXTRACT(DAY FROM r.prod_date);
        v_is_l1 := (r.line_code = 'LINE-1');

        -- Cycle products
        v_prod_cursor := ((EXTRACT(DOY FROM r.prod_date)::int * 2 + r.shift_seq + CASE WHEN v_is_l1 THEN 0 ELSE 2 END) % 5) + 1;
        SELECT * INTO v_prod FROM products WHERE product_id = v_prod_ids[v_prod_cursor];
        SELECT * INTO v_std FROM product_line_standards WHERE product_id = v_prod.product_id AND line_id = r.line_id;

        -- Planned quantity: 420 minutes * ideal_upm * 0.95
        v_planned_qty := round(420.0 * v_std.ideal_units_per_minute * 0.95, 0);

        -- Determine status relative to demo snapshot (2026-08-27 19:13:00-05)
        IF r.prod_date < DATE '2026-08-27' OR (r.prod_date = DATE '2026-08-27' AND r.shift_code = 'PROD-A') THEN
            v_status := 'COMPLETE';
            v_actual_start := r.plan_start + make_interval(mins => ((v_day * 3 + v_seq) % 7) - 2);
            v_actual_end := r.plan_end + make_interval(mins => ((v_day * 5 + v_seq) % 9) - 3);

            -- Model line-specific performance & availability
            IF v_is_l1 THEN
                -- Line 1: High availability (96-98%), High performance (93-96%), High quality (98.5-99.2%)
                v_runtime := 405.0 - ((v_day + v_seq) % 10);
                v_total_qty := round(v_runtime * v_std.ideal_units_per_minute * (0.935 + ((v_day % 5) * 0.005)), 0);
                v_reject_qty := round(v_total_qty * (0.008 + ((v_day % 4) * 0.002)), 0);
                v_good_qty := v_total_qty - v_reject_qty;
            ELSE
                -- Line 2: Affected by Filler-201 and Conveyor-201
                IF v_month <= 5 THEN
                    -- Pre-RCA period: lower availability (85-89%)
                    v_filler_down := 35.0 + ((v_day * 7 + v_seq) % 25);
                    v_conv_down := 15.0 + ((v_day * 3) % 15);
                    v_runtime := 420.0 - (v_filler_down + v_conv_down);
                    v_total_qty := round(v_runtime * v_std.ideal_units_per_minute * (0.915 + ((v_day % 4) * 0.005)), 0);
                    v_reject_qty := round(v_total_qty * (0.015 + ((v_day % 5) * 0.003)), 0);
                    v_good_qty := v_total_qty - v_reject_qty;
                ELSE
                    -- Post-RCA period: improved availability (91-94%), improved OEE
                    v_filler_down := 8.0 + ((v_day * 3) % 10);
                    v_conv_down := 12.0 + ((v_day * 2) % 10);
                    v_runtime := 420.0 - (v_filler_down + v_conv_down);
                    v_total_qty := round(v_runtime * v_std.ideal_units_per_minute * (0.930 + ((v_day % 5) * 0.004)), 0);
                    v_reject_qty := round(v_total_qty * (0.010 + ((v_day % 4) * 0.002)), 0);
                    v_good_qty := v_total_qty - v_reject_qty;
                END IF;
            END IF;

        ELSIF r.prod_date = DATE '2026-08-27' AND r.shift_code = 'PROD-B' THEN
            -- Currently RUNNING at 19:13
            v_status := 'RUNNING';
            v_actual_start := r.plan_start + interval '2 minutes';
            v_actual_end := NULL;
            -- Current progress up to 19:13 (~310 min elapsed)
            v_runtime := 295.0;
            v_total_qty := round(v_runtime * v_std.ideal_units_per_minute * 0.94, 0);
            v_reject_qty := round(v_total_qty * 0.01, 0);
            v_good_qty := v_total_qty - v_reject_qty;

        ELSIF r.prod_date = DATE '2026-08-28' AND r.shift_code = 'PROD-A' THEN
            v_status := 'READY';
            v_actual_start := NULL;
            v_actual_end := NULL;
            v_runtime := 0;
            v_total_qty := 0;
            v_good_qty := 0;
            v_reject_qty := 0;
        ELSE
            v_status := 'PLANNED';
            v_actual_start := NULL;
            v_actual_end := NULL;
            v_runtime := 0;
            v_total_qty := 0;
            v_good_qty := 0;
            v_reject_qty := 0;
        END IF;

        -- Insert Production Lot
        INSERT INTO production_lots (
            lot_number, product_id, line_id, planned_start, planned_end, actual_start, actual_end,
            planned_quantity, total_quantity, good_quantity, reject_quantity, status
        )
        VALUES (
            'ATX-' || to_char(r.prod_date, 'YYYYMMDD') || '-' || CASE WHEN v_is_l1 THEN 'L1' ELSE 'L2' END || '-' || lpad(r.shift_seq::text, 3, '0'),
            v_prod.product_id,
            r.line_id,
            r.plan_start,
            r.plan_end,
            v_actual_start,
            v_actual_end,
            v_planned_qty,
            v_total_qty,
            v_good_qty,
            v_reject_qty,
            v_status
        )
        RETURNING lot_id INTO v_lot_id;

        -- Insert Production Schedule
        INSERT INTO production_schedule (
            production_date, shift_id, line_id, lot_id, scheduled_start, scheduled_end, sequence_number, schedule_status
        )
        VALUES (
            r.prod_date,
            r.shift_id,
            r.line_id,
            v_lot_id,
            r.plan_start,
            r.plan_end,
            r.shift_seq,
            CASE v_status
                WHEN 'COMPLETE' THEN 'COMPLETED'
                WHEN 'RUNNING' THEN 'IN_PROGRESS'
                WHEN 'READY' THEN 'SCHEDULED'
                ELSE 'SCHEDULED'
            END
        );

        -- Insert Lot Events
        INSERT INTO production_lot_events (lot_id, event_type, event_timestamp, notes)
        VALUES (v_lot_id, 'CREATED', r.plan_start - interval '1 hour', 'Production lot created from master schedule');

        IF v_status IN ('READY', 'RUNNING', 'COMPLETE') THEN
            INSERT INTO production_lot_events (lot_id, event_type, event_timestamp, notes)
            VALUES (v_lot_id, 'READY', r.plan_start - interval '15 minutes', 'Pre-run inspection completed and staging verified');
        END IF;

        IF v_status IN ('RUNNING', 'COMPLETE') THEN
            INSERT INTO production_lot_events (lot_id, event_type, event_timestamp, notes)
            VALUES (v_lot_id, 'STARTED', v_actual_start, 'Production run initiated on ' || r.line_code);
        END IF;

        IF v_status = 'COMPLETE' THEN
            INSERT INTO production_lot_events (lot_id, event_type, event_timestamp, notes)
            VALUES (v_lot_id, 'COMPLETED', v_actual_end, 'Production lot finished with ' || v_good_qty || ' good units produced');
        END IF;

        -- Insert Lot-Asset Relationships & Equipment Production Runs
        -- Assets for Line 1: MIXER-101, BLENDER-001, CONVEYOR-101, FILLER-101, LABELER-101
        -- Assets for Line 2: MIXER-201, BLENDER-001, CONVEYOR-201, FILLER-201, LABELER-201
        INSERT INTO production_lot_assets (lot_id, asset_id, sequence_number, planned_start, planned_end, actual_start, actual_end)
        SELECT
            v_lot_id,
            a.asset_id,
            CASE a.equipment_type
                WHEN 'MIXER' THEN 1
                WHEN 'BLENDER' THEN 2
                WHEN 'CONVEYOR' THEN 3
                WHEN 'FILLER' THEN 4
                WHEN 'LABELER' THEN 5
            END,
            CASE
                WHEN a.asset_code = 'BLENDER-001' THEN
                    -- Blender-001 is shared between Line 1 and Line 2
                    -- Line 1 uses Blender in first half of shift; Line 2 uses Blender in second half
                    CASE
                        WHEN v_is_l1 THEN r.plan_start
                        ELSE r.plan_start + interval '3 hours 30 minutes'
                    END
                ELSE r.plan_start
            END,
            CASE
                WHEN a.asset_code = 'BLENDER-001' THEN
                    CASE
                        WHEN v_is_l1 THEN r.plan_start + interval '3 hours 30 minutes'
                        ELSE r.plan_end
                    END
                ELSE r.plan_end
            END,
            CASE
                WHEN v_actual_start IS NULL THEN NULL
                WHEN a.asset_code = 'BLENDER-001' THEN
                    CASE
                        WHEN v_is_l1 THEN v_actual_start
                        ELSE v_actual_start + interval '3 hours 30 minutes'
                    END
                ELSE v_actual_start
            END,
            CASE
                WHEN v_actual_end IS NULL THEN NULL
                WHEN a.asset_code = 'BLENDER-001' THEN
                    CASE
                        WHEN v_is_l1 THEN v_actual_start + interval '3 hours 30 minutes'
                        ELSE v_actual_end
                    END
                ELSE v_actual_end
            END
        FROM assets a
        WHERE (v_is_l1 AND a.asset_code IN ('MIXER-101', 'BLENDER-001', 'CONVEYOR-101', 'FILLER-101', 'LABELER-101'))
           OR (NOT v_is_l1 AND a.asset_code IN ('MIXER-201', 'BLENDER-001', 'CONVEYOR-201', 'FILLER-201', 'LABELER-201'));

        -- Equipment Production Runs (OEE metrics per equipment per lot)
        -- Excludes AIR-COMP-001
        IF v_status IN ('COMPLETE', 'RUNNING') THEN
            INSERT INTO equipment_production_runs (
                lot_id, asset_id, planned_minutes, runtime_minutes, ideal_rate, total_count, good_count, reject_count
            )
            SELECT
                v_lot_id,
                a.asset_id,
                CASE WHEN a.asset_code = 'BLENDER-001' THEN 210.0 ELSE 420.0 END AS plan_mins,
                CASE
                    WHEN a.asset_code = 'BLENDER-001' THEN round(v_runtime * 0.5, 2)
                    WHEN a.asset_code = 'FILLER-201' AND v_month <= 5 THEN round(v_runtime, 2)
                    WHEN a.asset_code = 'CONVEYOR-201' THEN round(v_runtime + 5.0, 2)
                    ELSE round(LEAST(420.0, v_runtime + 10.0), 2)
                END AS run_mins,
                CASE
                    -- For Blender-001, processing window is 210 min for a 420 min line lot, so ideal rate is 2x line rate
                    WHEN a.asset_code = 'BLENDER-001' THEN round(v_std.ideal_units_per_minute * 2.0 * 1.02, 2)
                    WHEN a.equipment_type = 'MIXER' THEN round(v_std.ideal_units_per_minute * 1.02, 2)
                    ELSE v_std.ideal_units_per_minute
                END AS ideal_r,
                v_total_qty,
                v_good_qty,
                v_reject_qty
            FROM assets a
            WHERE (v_is_l1 AND a.asset_code IN ('MIXER-101', 'BLENDER-001', 'CONVEYOR-101', 'FILLER-101', 'LABELER-101'))
               OR (NOT v_is_l1 AND a.asset_code IN ('MIXER-201', 'BLENDER-001', 'CONVEYOR-201', 'FILLER-201', 'LABELER-201'));
        END IF;

        v_seq := v_seq + 1;
    END LOOP;
END $$;

COMMIT;
