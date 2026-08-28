BEGIN;

-- One database-owned clock makes every live-like interview panel deterministic.
-- Historical analytics continue to use their recorded event timestamps.
CREATE TABLE IF NOT EXISTS demo_context (
    demo_context_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    context_name text NOT NULL UNIQUE,
    anchor_timestamp timestamptz NOT NULL,
    description text NOT NULL,
    active boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_demo_context_one_active
    ON demo_context (active) WHERE active;

COMMENT ON TABLE demo_context IS
    'Database-owned fixed timestamps for repeatable hypothetical demonstrations; current semantic views never depend on workstation time.';
COMMENT ON COLUMN demo_context.anchor_timestamp IS
    'Fixed demonstration clock used by current/active/latest semantic views. It is not actual plant time.';

CREATE OR REPLACE VIEW v_demo_context_active AS
SELECT demo_context_id, context_name, anchor_timestamp, description
FROM demo_context
WHERE active;

-- Existing live-risk views retain their public columns while replacing wall-clock
-- age and overdue decisions with the same fixed demonstration anchor.
CREATE OR REPLACE VIEW v_open_critical_work_orders AS
SELECT w.work_order_number, a.asset_code, w.priority, w.title, w.requested_at, w.status,
       round(EXTRACT(epoch FROM (dc.anchor_timestamp - w.requested_at)) / 3600.0, 2) AS age_hours
FROM work_orders w
LEFT JOIN assets a USING (asset_id)
CROSS JOIN v_demo_context_active dc
WHERE w.priority = 'CRITICAL' AND w.status NOT IN ('CLOSED', 'CANCELLED');

CREATE OR REPLACE VIEW v_overdue_pm AS
SELECT p.pm_code, a.asset_code, e.scheduled_date, e.status,
       dc.anchor_timestamp::date - e.scheduled_date AS days_overdue
FROM pm_executions e
JOIN pm_plans p USING (pm_plan_id)
JOIN assets a USING (asset_id)
CROSS JOIN v_demo_context_active dc
WHERE e.status NOT IN ('COMPLETED', 'CANCELLED')
  AND e.scheduled_date < dc.anchor_timestamp::date;

CREATE OR REPLACE VIEW v_open_rca_actions AS
SELECT r.rca_number, w.work_order_number, a.asset_code, c.corrective_action_id,
       c.action_description, c.action_type, c.due_date,
       c.due_date < dc.anchor_timestamp::date AS overdue
FROM corrective_actions c
JOIN rca_events r USING (rca_event_id)
JOIN work_orders w USING (work_order_id)
LEFT JOIN assets a USING (asset_id)
CROSS JOIN v_demo_context_active dc
WHERE c.completed_date IS NULL;

CREATE OR REPLACE VIEW v_current_production_status AS
SELECT
    dc.context_name,
    dc.anchor_timestamp,
    l.line_id,
    l.line_code,
    l.name AS line_name,
    pl.lot_id,
    pl.lot_number,
    p.product_code,
    p.product_name,
    s.shift_id,
    s.shift_code,
    s.name AS shift_name,
    ps.scheduled_start,
    ps.scheduled_end,
    pl.actual_start,
    pl.status,
    ps.schedule_status,
    pl.planned_quantity,
    pl.total_quantity,
    pl.good_quantity,
    pl.reject_quantity,
    round(100.0 * pl.total_quantity / NULLIF(pl.planned_quantity, 0), 1) AS progress_percent,
    round(100.0 * pl.good_quantity / NULLIF(pl.total_quantity, 0), 2) AS yield_percent,
    round(pl.total_quantity / NULLIF(EXTRACT(epoch FROM (dc.anchor_timestamp - pl.actual_start)) / 60.0, 0), 2) AS current_rate,
    string_agg(DISTINCT a.asset_code, ', ' ORDER BY a.asset_code) AS assigned_assets,
    string_agg(DISTINCT e.first_name || ' ' || e.last_name || ' (' || es.assigned_role || ')', ', '
               ORDER BY e.first_name || ' ' || e.last_name || ' (' || es.assigned_role || ')') AS assigned_employees
FROM v_demo_context_active dc
JOIN production_schedule ps
  ON dc.anchor_timestamp >= ps.scheduled_start
 AND dc.anchor_timestamp < ps.scheduled_end
JOIN production_lots pl ON pl.lot_id = ps.lot_id AND pl.status = 'RUNNING'
JOIN production_lines l ON l.line_id = ps.line_id
JOIN products p ON p.product_id = pl.product_id
JOIN shifts s ON s.shift_id = ps.shift_id
LEFT JOIN production_lot_assets pla ON pla.lot_id = pl.lot_id
LEFT JOIN assets a ON a.asset_id = pla.asset_id
LEFT JOIN employee_schedules es
  ON es.shift_id = ps.shift_id
 AND es.schedule_date = ps.production_date
 AND dc.anchor_timestamp >= es.scheduled_start
 AND dc.anchor_timestamp < es.scheduled_end
 AND es.status IN ('SCHEDULED', 'CONFIRMED')
 AND (es.line_id IS NULL OR es.line_id = ps.line_id)
LEFT JOIN employees e ON e.employee_id = es.employee_id AND e.active
GROUP BY dc.context_name, dc.anchor_timestamp, l.line_id, l.line_code, l.name,
         pl.lot_id, pl.lot_number, p.product_code, p.product_name,
         s.shift_id, s.shift_code, s.name, ps.scheduled_start, ps.scheduled_end,
         pl.actual_start, pl.status, ps.schedule_status, pl.planned_quantity,
         pl.total_quantity, pl.good_quantity, pl.reject_quantity;

CREATE OR REPLACE VIEW v_current_line1_production_status AS
SELECT * FROM v_current_production_status WHERE line_code = 'LINE-1';

CREATE OR REPLACE VIEW v_current_line2_production_status AS
SELECT * FROM v_current_production_status WHERE line_code = 'LINE-2';

-- Compatibility view retained for existing consumers, now governed by demo_context.
CREATE OR REPLACE VIEW v_current_production_lots AS
SELECT line_id, line_code, line_name, lot_id, lot_number, product_code, product_name,
       status, scheduled_start AS planned_start, scheduled_end AS planned_end,
       actual_start, planned_quantity, total_quantity, good_quantity, reject_quantity,
       progress_percent, yield_percent
FROM v_current_production_status
ORDER BY line_code;

CREATE OR REPLACE VIEW v_current_shift_staffing AS
SELECT
    dc.context_name,
    dc.anchor_timestamp,
    es.employee_schedule_id,
    e.employee_number,
    e.first_name || ' ' || e.last_name AS employee_name,
    e.job_title,
    e.department,
    es.assigned_role,
    s.shift_code,
    s.name AS shift_name,
    COALESCE(l.line_code, 'PLANT-WIDE') AS line_assignment,
    es.scheduled_start,
    es.scheduled_end,
    es.status
FROM v_demo_context_active dc
JOIN employee_schedules es
  ON dc.anchor_timestamp >= es.scheduled_start
 AND dc.anchor_timestamp < es.scheduled_end
 AND es.status IN ('SCHEDULED', 'CONFIRMED')
JOIN employees e ON e.employee_id = es.employee_id AND e.active
JOIN shifts s ON s.shift_id = es.shift_id
LEFT JOIN production_lines l ON l.line_id = es.line_id
ORDER BY e.department, es.assigned_role, e.employee_number;

CREATE OR REPLACE VIEW v_current_equipment_state AS
SELECT
    dc.context_name,
    dc.anchor_timestamp,
    a.asset_id,
    a.asset_code,
    a.name AS asset_name,
    a.equipment_type,
    l.line_code,
    e.state_event_id,
    e.state_code,
    e.start_time AS most_recent_state_timestamp,
    (e.state_code = 'RUNNING') AS run_status,
    r.stop_reason_code AS current_fault_code,
    r.display_name AS current_fault,
    pl.lot_id,
    pl.lot_number,
    p.product_code,
    p.product_name,
    sh.shift_id,
    sh.shift_code,
    op.operator_name
FROM v_demo_context_active dc
JOIN equipment_state_events e
  ON dc.anchor_timestamp >= e.start_time
 AND dc.anchor_timestamp < e.end_time
JOIN assets a ON a.asset_id = e.asset_id
JOIN asset_line_relationships alr ON alr.asset_id = a.asset_id
JOIN production_lines l ON l.line_id = alr.line_id
LEFT JOIN stop_reason_definitions r ON r.stop_reason_id = e.primary_stop_reason_id
LEFT JOIN production_lots pl ON pl.lot_id = e.lot_id
LEFT JOIN products p ON p.product_id = pl.product_id
LEFT JOIN shifts sh ON sh.shift_id = e.shift_id
LEFT JOIN LATERAL (
    SELECT emp.first_name || ' ' || emp.last_name AS operator_name
    FROM employee_schedules x
    JOIN employees emp ON emp.employee_id = x.employee_id
    WHERE x.line_id = pl.line_id
      AND x.assigned_role ILIKE '%operator%'
      AND dc.anchor_timestamp >= x.scheduled_start
      AND dc.anchor_timestamp < x.scheduled_end
      AND x.status IN ('SCHEDULED', 'CONFIRMED')
    ORDER BY emp.employee_number
    LIMIT 1
) op ON true
WHERE a.asset_code IN ('MIXER-201', 'CONVEYOR-201', 'FILLER-201', 'LABELER-201');

CREATE OR REPLACE VIEW v_current_sensor_state AS
SELECT DISTINCT ON (s.sensor_id)
    dc.context_name,
    dc.anchor_timestamp,
    a.asset_code,
    s.sensor_id,
    s.sensor_code,
    s.sensor_type,
    s.engineering_unit,
    s.functional_class,
    sr.observed_at,
    sr.numeric_value,
    sr.discrete_value,
    sr.quality_status,
    pl.lot_number,
    sh.shift_code
FROM v_demo_context_active dc
JOIN sensor_readings sr ON sr.observed_at <= dc.anchor_timestamp
JOIN equipment_sensors s ON s.sensor_id = sr.sensor_id AND s.active
JOIN assets a ON a.asset_id = s.asset_id
LEFT JOIN production_lots pl ON pl.lot_id = sr.lot_id
LEFT JOIN shifts sh ON sh.shift_id = sr.shift_id
WHERE a.asset_code IN ('MIXER-201', 'CONVEYOR-201', 'FILLER-201', 'LABELER-201')
ORDER BY s.sensor_id, sr.observed_at DESC, sr.reading_id DESC;

-- Compatibility view used by Equipment OEE Detail, now strictly anchor-relative.
CREATE OR REPLACE VIEW v_line2_equipment_current AS
SELECT ces.asset_code, ces.asset_name, ces.equipment_type, ces.line_code,
       ces.lot_number, ces.product_name, ces.shift_code, ces.operator_name,
       ces.state_code, ces.current_fault, ces.most_recent_state_timestamp AS last_state_change,
       max(css.observed_at) AS last_sensor_update
FROM v_current_equipment_state ces
LEFT JOIN v_current_sensor_state css ON css.asset_code = ces.asset_code
GROUP BY ces.asset_code, ces.asset_name, ces.equipment_type, ces.line_code,
         ces.lot_number, ces.product_name, ces.shift_code, ces.operator_name,
         ces.state_code, ces.current_fault, ces.most_recent_state_timestamp;

CREATE OR REPLACE VIEW v_current_month_schedule_adherence AS
SELECT psa.*
FROM v_production_schedule_adherence psa
CROSS JOIN v_demo_context_active dc
WHERE psa.period = date_trunc('month', dc.anchor_timestamp)::date;

COMMIT;
