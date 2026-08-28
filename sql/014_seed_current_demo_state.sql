BEGIN;

INSERT INTO demo_context (context_name, anchor_timestamp, description, active)
VALUES (
    'INTERVIEW_DEMO',
    TIMESTAMPTZ '2026-08-28 10:00:00-05',
    'Fixed operating-state anchor for repeatable Grafana interview demonstration',
    true
)
ON CONFLICT (context_name) DO UPDATE SET
    anchor_timestamp = EXCLUDED.anchor_timestamp,
    description = EXCLUDED.description,
    active = EXCLUDED.active;

UPDATE demo_context SET active = false WHERE context_name <> 'INTERVIEW_DEMO' AND active;

-- Promote the already-related Aug 28 Shift A schedule into the fixed live-like state.
UPDATE production_lots
SET status = 'RUNNING',
    actual_start = CASE lot_number
        WHEN 'ATX-20260828-L1-001' THEN TIMESTAMPTZ '2026-08-28 06:04:00-05'
        WHEN 'ATX-20260828-L2-001' THEN TIMESTAMPTZ '2026-08-28 06:02:00-05'
    END,
    actual_end = NULL,
    total_quantity = CASE lot_number
        WHEN 'ATX-20260828-L1-001' THEN 25200
        WHEN 'ATX-20260828-L2-001' THEN 23000
    END,
    good_quantity = CASE lot_number
        WHEN 'ATX-20260828-L1-001' THEN 24900
        WHEN 'ATX-20260828-L2-001' THEN 22620
    END,
    reject_quantity = CASE lot_number
        WHEN 'ATX-20260828-L1-001' THEN 300
        WHEN 'ATX-20260828-L2-001' THEN 380
    END
WHERE lot_number IN ('ATX-20260828-L1-001', 'ATX-20260828-L2-001');

UPDATE production_schedule
SET schedule_status = 'IN_PROGRESS'
WHERE lot_id IN (
    SELECT lot_id FROM production_lots
    WHERE lot_number IN ('ATX-20260828-L1-001', 'ATX-20260828-L2-001')
);

INSERT INTO production_lot_events (lot_id, event_type, event_timestamp, notes)
SELECT pl.lot_id, 'STARTED', pl.actual_start,
       'Deterministic start event for the fixed INTERVIEW_DEMO operating state.'
FROM production_lots pl
WHERE pl.lot_number IN ('ATX-20260828-L1-001', 'ATX-20260828-L2-001')
  AND NOT EXISTS (
      SELECT 1 FROM production_lot_events e
      WHERE e.lot_id = pl.lot_id AND e.event_type = 'STARTED' AND e.event_timestamp = pl.actual_start
  );

UPDATE employee_schedules
SET status = 'CONFIRMED'
WHERE schedule_date = DATE '2026-08-28'
  AND shift_id = (SELECT shift_id FROM shifts WHERE shift_code = 'PROD-A')
  AND status = 'SCHEDULED';

-- Normalize an earlier rerun of this same seed without touching historical events.
UPDATE equipment_state_events
SET end_time = TIMESTAMPTZ '2026-08-28 10:01:00-05'
WHERE start_time = TIMESTAMPTZ '2026-08-28 09:50:00-05'
  AND end_time = TIMESTAMPTZ '2026-08-28 14:00:00-05'
  AND evidence ->> 'demo_context' = 'INTERVIEW_DEMO';

WITH current_lot AS (
    SELECT lot_id FROM production_lots WHERE lot_number = 'ATX-20260828-L2-001'
), current_shift AS (
    SELECT shift_id FROM shifts WHERE shift_code = 'PROD-A'
), states(asset_code, state_code) AS (
    VALUES
        ('MIXER-201', 'RUNNING'),
        ('CONVEYOR-201', 'RUNNING'),
        ('FILLER-201', 'RUNNING'),
        ('LABELER-201', 'RUNNING')
)
INSERT INTO equipment_state_events
    (asset_id, lot_id, shift_id, state_code, start_time, end_time,
     reason_source, reason_confidence, evidence)
SELECT a.asset_id, cl.lot_id, cs.shift_id, s.state_code,
       TIMESTAMPTZ '2026-08-28 09:50:00-05',
       TIMESTAMPTZ '2026-08-28 10:01:00-05',
       'SYSTEM_RULE', 1.00,
       jsonb_build_object(
           'demo_context', 'INTERVIEW_DEMO',
           'scheduled_production', true,
           'run_request', true,
           'asset_running', true,
           'hypothetical_demo_state', true
       )
FROM states s
JOIN assets a USING (asset_code)
CROSS JOIN current_lot cl
CROSS JOIN current_shift cs
ON CONFLICT (asset_id, start_time, end_time) DO UPDATE SET
    lot_id = EXCLUDED.lot_id,
    shift_id = EXCLUDED.shift_id,
    state_code = EXCLUDED.state_code,
    primary_stop_reason_id = NULL,
    reason_source = EXCLUDED.reason_source,
    reason_confidence = EXCLUDED.reason_confidence,
    evidence = EXCLUDED.evidence;

WITH current_lot AS (
    SELECT lot_id FROM production_lots WHERE lot_number = 'ATX-20260828-L2-001'
), current_shift AS (
    SELECT shift_id FROM shifts WHERE shift_code = 'PROD-A'
), values_at_anchor(sensor_code, numeric_value, discrete_value) AS (
    VALUES
        ('MIXER-201_RUN_STATE', NULL::numeric, 'RUNNING'),
        ('MIXER-201_FAULT_STATE', NULL, 'CLEAR'),
        ('MIXER-201_BATCH_COUNT', 5, NULL),
        ('MIXER-201_BATCH_CYCLE', 43.8, NULL),
        ('MIXER-201_MOTOR_CURRENT', 31.6, NULL),
        ('MIXER-201_TEMPERATURE', 72.4, NULL),
        ('MIXER-201_VIBRATION', 1.7, NULL),
        ('CONVEYOR-201_RUN_STATE', NULL, 'RUNNING'),
        ('CONVEYOR-201_FAULT_STATE', NULL, 'CLEAR'),
        ('CONVEYOR-201_PRODUCT_COUNT', 23040, NULL),
        ('CONVEYOR-201_SPEED', 105.2, NULL),
        ('CONVEYOR-201_JAM_STATE', NULL, 'CLEAR'),
        ('CONVEYOR-201_MOTOR_CURRENT', 12.8, NULL),
        ('CONVEYOR-201_BELT_TRACKING', 1.4, NULL),
        ('FILLER-201_RUN_STATE', NULL, 'RUNNING'),
        ('FILLER-201_FAULT_STATE', NULL, 'CLEAR'),
        ('FILLER-201_TOTAL_COUNT', 23000, NULL),
        ('FILLER-201_GOOD_COUNT', 22620, NULL),
        ('FILLER-201_REJECT_COUNT', 380, NULL),
        ('FILLER-201_ACTUAL_RATE', 103.8, NULL),
        ('FILLER-201_PHOTOEYE_STATE', NULL, 'PRODUCT_DETECTED'),
        ('FILLER-201_PHOTOEYE_FAULT', NULL, 'CLEAR'),
        ('FILLER-201_CYCLE_TIME', 0.578, NULL),
        ('LABELER-201_RUN_STATE', NULL, 'RUNNING'),
        ('LABELER-201_FAULT_STATE', NULL, 'CLEAR'),
        ('LABELER-201_TOTAL_COUNT', 22940, NULL),
        ('LABELER-201_REJECT_COUNT', 42, NULL),
        ('LABELER-201_ACTUAL_RATE', 103.4, NULL),
        ('LABELER-201_LABEL_PRESENT', NULL, 'PRESENT'),
        ('LABELER-201_CYCLE_TIME', 0.580, NULL)
)
INSERT INTO sensor_readings
    (sensor_id, observed_at, numeric_value, discrete_value, quality_status, lot_id, shift_id)
SELECT s.sensor_id, TIMESTAMPTZ '2026-08-28 09:59:00-05',
       v.numeric_value, v.discrete_value, 'GOOD', cl.lot_id, cs.shift_id
FROM values_at_anchor v
JOIN equipment_sensors s USING (sensor_code)
CROSS JOIN current_lot cl
CROSS JOIN current_shift cs
ON CONFLICT (sensor_id, observed_at) DO UPDATE SET
    numeric_value = EXCLUDED.numeric_value,
    discrete_value = EXCLUDED.discrete_value,
    quality_status = EXCLUDED.quality_status,
    lot_id = EXCLUDED.lot_id,
    shift_id = EXCLUDED.shift_id;

COMMIT;
