BEGIN;

-- 1. Current Production Lots (Active snapshot)
CREATE OR REPLACE VIEW v_current_production_lots AS
SELECT
    l.line_id,
    l.line_code,
    l.name AS line_name,
    pl.lot_id,
    pl.lot_number,
    p.product_code,
    p.product_name,
    pl.status,
    pl.planned_start,
    pl.planned_end,
    pl.actual_start,
    pl.planned_quantity,
    pl.total_quantity,
    pl.good_quantity,
    pl.reject_quantity,
    CASE
        WHEN pl.planned_quantity > 0 THEN round((pl.total_quantity / pl.planned_quantity) * 100.0, 1)
        ELSE 0
    END AS progress_percent,
    CASE
        WHEN pl.total_quantity > 0 THEN round((pl.good_quantity / pl.total_quantity) * 100.0, 2)
        ELSE 100.00
    END AS yield_percent
FROM production_lots pl
JOIN production_lines l ON l.line_id = pl.line_id
JOIN products p ON p.product_id = pl.product_id
WHERE pl.status = 'RUNNING'
ORDER BY l.line_code;

-- 2. Upcoming Production Lots
CREATE OR REPLACE VIEW v_upcoming_production_lots AS
SELECT
    l.line_id,
    l.line_code,
    l.name AS line_name,
    pl.lot_id,
    pl.lot_number,
    p.product_code,
    p.product_name,
    ps.scheduled_start,
    ps.scheduled_end,
    ps.sequence_number,
    pl.planned_quantity,
    pl.status
FROM production_schedule ps
JOIN production_lots pl ON pl.lot_id = ps.lot_id
JOIN production_lines l ON l.line_id = ps.line_id
JOIN products p ON p.product_id = pl.product_id
WHERE pl.status IN ('READY', 'PLANNED')
ORDER BY ps.scheduled_start, l.line_code, ps.sequence_number;

-- 3. Completed Production Lots History
CREATE OR REPLACE VIEW v_completed_production_lots AS
SELECT
    pl.lot_id,
    pl.lot_number,
    l.line_code,
    l.name AS line_name,
    p.product_code,
    p.product_name,
    pl.planned_start,
    pl.actual_start,
    pl.actual_end,
    round(EXTRACT(epoch FROM (pl.actual_end - pl.actual_start)) / 60.0, 1) AS actual_duration_minutes,
    pl.planned_quantity,
    pl.total_quantity,
    pl.good_quantity,
    pl.reject_quantity,
    CASE
        WHEN pl.total_quantity > 0 THEN round((pl.good_quantity / pl.total_quantity) * 100.0, 2)
        ELSE 0
    END AS yield_percent,
    pl.status
FROM production_lots pl
JOIN production_lines l ON l.line_id = pl.line_id
JOIN products p ON p.product_id = pl.product_id
WHERE pl.status = 'COMPLETE'
ORDER BY pl.actual_end DESC;

-- 4. Production Schedule Adherence (10-minute tolerance standard)
CREATE OR REPLACE VIEW v_production_schedule_adherence AS
WITH adherence_data AS (
    SELECT
        ps.production_date,
        date_trunc('month', ps.production_date)::date AS period,
        l.line_code,
        l.name AS line_name,
        ps.schedule_id,
        pl.lot_number,
        ps.scheduled_start,
        pl.actual_start,
        round(EXTRACT(epoch FROM (pl.actual_start - ps.scheduled_start)) / 60.0, 1) AS start_variance_minutes,
        ps.scheduled_end,
        pl.actual_end,
        round(EXTRACT(epoch FROM (pl.actual_end - ps.scheduled_end)) / 60.0, 1) AS end_variance_minutes,
        (pl.actual_start IS NOT NULL AND abs(EXTRACT(epoch FROM (pl.actual_start - ps.scheduled_start)) / 60.0) <= 10.0) AS on_time_start,
        (pl.actual_end IS NOT NULL AND abs(EXTRACT(epoch FROM (pl.actual_end - ps.scheduled_end)) / 60.0) <= 10.0) AS on_time_complete
    FROM production_schedule ps
    JOIN production_lots pl ON pl.lot_id = ps.lot_id
    JOIN production_lines l ON l.line_id = ps.line_id
    WHERE pl.status = 'COMPLETE'
)
SELECT
    period,
    line_code,
    line_name,
    count(*) AS scheduled_lots,
    count(*) FILTER (WHERE on_time_start) AS on_time_start_count,
    round(100.0 * count(*) FILTER (WHERE on_time_start) / NULLIF(count(*), 0), 2) AS on_time_start_percent,
    count(*) FILTER (WHERE on_time_complete) AS on_time_complete_count,
    round(100.0 * count(*) FILTER (WHERE on_time_complete) / NULLIF(count(*), 0), 2) AS on_time_complete_percent,
    round(avg(abs(start_variance_minutes)), 2) AS avg_abs_start_variance_minutes,
    round(avg(abs(end_variance_minutes)), 2) AS avg_abs_end_variance_minutes
FROM adherence_data
GROUP BY period, line_code, line_name
ORDER BY period, line_code;

-- 5. Current Employee Schedule (Active snapshot)
CREATE OR REPLACE VIEW v_employee_schedule_current AS
SELECT
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
FROM employee_schedules es
JOIN employees e ON e.employee_id = es.employee_id
JOIN shifts s ON s.shift_id = es.shift_id
LEFT JOIN production_lines l ON l.line_id = es.line_id
WHERE es.schedule_date = DATE '2026-08-27'
  AND s.shift_code = 'PROD-B'
ORDER BY e.department, es.assigned_role, e.employee_number;

-- 6. Daily Employee Schedule Roster
CREATE OR REPLACE VIEW v_employee_schedule_daily AS
SELECT
    es.schedule_date,
    s.shift_code,
    s.name AS shift_name,
    e.employee_number,
    e.first_name || ' ' || e.last_name AS employee_name,
    e.department,
    es.assigned_role,
    COALESCE(l.line_code, 'PLANT-WIDE') AS line_assignment,
    es.scheduled_start,
    es.scheduled_end,
    es.overtime_type,
    es.status
FROM employee_schedules es
JOIN employees e ON e.employee_id = es.employee_id
JOIN shifts s ON s.shift_id = es.shift_id
LEFT JOIN production_lines l ON l.line_id = es.line_id
ORDER BY es.schedule_date DESC, s.shift_code, es.assigned_role;

-- 7. Shift Staffing Coverage (1/1/0 rule validation)
CREATE OR REPLACE VIEW v_shift_staffing_coverage AS
SELECT
    s.shift_code,
    s.name AS shift_name,
    s.function AS shift_function,
    count(DISTINCT es.employee_id) FILTER (WHERE es.assigned_role = 'Production Lead') AS production_leads,
    count(DISTINCT es.employee_id) FILTER (WHERE es.assigned_role = 'Line 1 Operator') AS line_1_operators,
    count(DISTINCT es.employee_id) FILTER (WHERE es.assigned_role = 'Line 2 Operator') AS line_2_operators,
    count(DISTINCT es.employee_id) FILTER (WHERE es.assigned_role = 'Maintenance Technician') AS maintenance_technicians,
    count(DISTINCT es.employee_id) FILTER (WHERE es.assigned_role LIKE 'Sanitation%') AS sanitation_technicians,
    CASE
        WHEN s.shift_code IN ('PROD-A', 'PROD-B') AND count(DISTINCT es.employee_id) FILTER (WHERE es.assigned_role = 'Maintenance Technician') = 1 THEN 'NORMAL_COVERAGE'
        WHEN s.shift_code = 'SAN' AND count(DISTINCT es.employee_id) FILTER (WHERE es.assigned_role = 'Maintenance Technician') = 0 THEN 'NO_NORMAL_MAINTENANCE'
        ELSE 'IRREGULAR_COVERAGE'
    END AS coverage_status
FROM shifts s
LEFT JOIN employee_schedules es ON es.shift_id = s.shift_id AND es.schedule_date = DATE '2026-08-27'
GROUP BY s.shift_id, s.shift_code, s.name, s.function
ORDER BY s.shift_code;

-- 8. Daily Equipment OEE (Excludes Utility AIR-COMP-001)
CREATE OR REPLACE VIEW v_asset_oee_daily AS
WITH daily_runs AS (
    SELECT
        ps.production_date,
        a.asset_id,
        a.asset_code,
        a.name AS asset_name,
        a.equipment_type,
        COALESCE(l.line_code, 'SHARED') AS line_code,
        sum(epr.planned_minutes) AS planned_minutes,
        sum(epr.runtime_minutes) AS runtime_minutes,
        avg(epr.ideal_rate) AS avg_ideal_rate,
        sum(epr.total_count) AS total_count,
        sum(epr.good_count) AS good_count,
        sum(epr.reject_count) AS reject_count
    FROM equipment_production_runs epr
    JOIN production_lots pl ON pl.lot_id = epr.lot_id
    JOIN assets a ON a.asset_id = epr.asset_id
    JOIN production_schedule ps ON ps.lot_id = pl.lot_id
    LEFT JOIN production_lines l ON l.line_id = pl.line_id
    WHERE a.scope <> 'SHARED_UTILITY'
    GROUP BY ps.production_date, a.asset_id, a.asset_code, a.name, a.equipment_type, l.line_code
)
SELECT
    production_date,
    asset_id,
    asset_code,
    asset_name,
    equipment_type,
    line_code,
    planned_minutes,
    runtime_minutes,
    total_count,
    good_count,
    reject_count,
    round(100.0 * (runtime_minutes / NULLIF(planned_minutes, 0)), 2) AS availability_percent,
    round(100.0 * (total_count / NULLIF(runtime_minutes * avg_ideal_rate, 0)), 2) AS performance_percent,
    round(100.0 * (good_count / NULLIF(total_count, 0)), 2) AS quality_percent,
    round(
        (100.0 * (runtime_minutes / NULLIF(planned_minutes, 0))) *
        (100.0 * (total_count / NULLIF(runtime_minutes * avg_ideal_rate, 0))) *
        (100.0 * (good_count / NULLIF(total_count, 0))) / 10000.0,
        2
    ) AS oee_percent
FROM daily_runs
ORDER BY production_date, line_code, asset_code;

-- 9. Weekly Equipment OEE
CREATE OR REPLACE VIEW v_asset_oee_weekly AS
WITH weekly_runs AS (
    SELECT
        date_trunc('week', ps.production_date)::date AS period,
        a.asset_id,
        a.asset_code,
        a.name AS asset_name,
        a.equipment_type,
        COALESCE(l.line_code, 'SHARED') AS line_code,
        sum(epr.planned_minutes) AS planned_minutes,
        sum(epr.runtime_minutes) AS runtime_minutes,
        avg(epr.ideal_rate) AS avg_ideal_rate,
        sum(epr.total_count) AS total_count,
        sum(epr.good_count) AS good_count,
        sum(epr.reject_count) AS reject_count
    FROM equipment_production_runs epr
    JOIN production_lots pl ON pl.lot_id = epr.lot_id
    JOIN assets a ON a.asset_id = epr.asset_id
    JOIN production_schedule ps ON ps.lot_id = pl.lot_id
    LEFT JOIN production_lines l ON l.line_id = pl.line_id
    WHERE a.scope <> 'SHARED_UTILITY'
    GROUP BY date_trunc('week', ps.production_date)::date, a.asset_id, a.asset_code, a.name, a.equipment_type, l.line_code
)
SELECT
    period,
    asset_id,
    asset_code,
    asset_name,
    equipment_type,
    line_code,
    planned_minutes,
    runtime_minutes,
    total_count,
    good_count,
    reject_count,
    round(100.0 * (runtime_minutes / NULLIF(planned_minutes, 0)), 2) AS availability_percent,
    round(100.0 * (total_count / NULLIF(runtime_minutes * avg_ideal_rate, 0)), 2) AS performance_percent,
    round(100.0 * (good_count / NULLIF(total_count, 0)), 2) AS quality_percent,
    round(
        (100.0 * (runtime_minutes / NULLIF(planned_minutes, 0))) *
        (100.0 * (total_count / NULLIF(runtime_minutes * avg_ideal_rate, 0))) *
        (100.0 * (good_count / NULLIF(total_count, 0))) / 10000.0,
        2
    ) AS oee_percent
FROM weekly_runs
ORDER BY period, line_code, asset_code;

-- 10. Monthly Equipment OEE
CREATE OR REPLACE VIEW v_asset_oee_monthly AS
WITH monthly_runs AS (
    SELECT
        date_trunc('month', ps.production_date)::date AS period,
        a.asset_id,
        a.asset_code,
        a.name AS asset_name,
        a.equipment_type,
        COALESCE(l.line_code, 'SHARED') AS line_code,
        sum(epr.planned_minutes) AS planned_minutes,
        sum(epr.runtime_minutes) AS runtime_minutes,
        avg(epr.ideal_rate) AS avg_ideal_rate,
        sum(epr.total_count) AS total_count,
        sum(epr.good_count) AS good_count,
        sum(epr.reject_count) AS reject_count
    FROM equipment_production_runs epr
    JOIN production_lots pl ON pl.lot_id = epr.lot_id
    JOIN assets a ON a.asset_id = epr.asset_id
    JOIN production_schedule ps ON ps.lot_id = pl.lot_id
    LEFT JOIN production_lines l ON l.line_id = pl.line_id
    WHERE a.scope <> 'SHARED_UTILITY'
    GROUP BY date_trunc('month', ps.production_date)::date, a.asset_id, a.asset_code, a.name, a.equipment_type, l.line_code
)
SELECT
    period,
    asset_id,
    asset_code,
    asset_name,
    equipment_type,
    line_code,
    planned_minutes,
    runtime_minutes,
    total_count,
    good_count,
    reject_count,
    round(100.0 * (runtime_minutes / NULLIF(planned_minutes, 0)), 2) AS availability_percent,
    round(100.0 * (total_count / NULLIF(runtime_minutes * avg_ideal_rate, 0)), 2) AS performance_percent,
    round(100.0 * (good_count / NULLIF(total_count, 0)), 2) AS quality_percent,
    round(
        (100.0 * (runtime_minutes / NULLIF(planned_minutes, 0))) *
        (100.0 * (total_count / NULLIF(runtime_minutes * avg_ideal_rate, 0))) *
        (100.0 * (good_count / NULLIF(total_count, 0))) / 10000.0,
        2
    ) AS oee_percent
FROM monthly_runs
ORDER BY period, line_code, asset_code;

-- 11. Daily Line OEE (Direct Line-System Calculation - NOT Average of Asset OEE)
CREATE OR REPLACE VIEW v_line_oee_daily AS
WITH line_daily AS (
    SELECT
        pc.production_date,
        l.line_id,
        l.line_code,
        l.name AS line_name,
        sum(pc.planned_production_minutes) AS planned_minutes,
        sum(pl.planned_quantity) AS planned_quantity,
        sum(pl.total_quantity) AS total_quantity,
        sum(pl.good_quantity) AS good_quantity,
        sum(pl.reject_quantity) AS reject_quantity,
        -- Weighted ideal rate by lot planned minutes
        sum(pls.ideal_units_per_minute * 420.0) / NULLIF(sum(420.0), 0) AS avg_ideal_rate,
        -- Line runtime derived from lot actual durations / runs
        sum(pl.total_quantity) / NULLIF(sum(pls.ideal_units_per_minute * 0.94), 0) * (420.0 / NULLIF(sum(pc.planned_production_minutes), 0) * sum(pc.planned_production_minutes)) / 420.0 AS est_runtime
    FROM production_calendar pc
    JOIN production_lines l ON l.line_id = pc.line_id
    JOIN production_schedule ps ON ps.production_date = pc.production_date AND ps.line_id = pc.line_id AND ps.shift_id = pc.shift_id
    JOIN production_lots pl ON pl.lot_id = ps.lot_id
    JOIN product_line_standards pls ON pls.product_id = pl.product_id AND pls.line_id = pl.line_id
    WHERE pl.status = 'COMPLETE'
    GROUP BY pc.production_date, l.line_id, l.line_code, l.name
)
SELECT
    production_date,
    line_id,
    line_code,
    line_name,
    planned_minutes,
    round(LEAST(planned_minutes, GREATEST(0, planned_minutes * (total_quantity / NULLIF(planned_quantity, 0)) * 1.01)), 2) AS runtime_minutes,
    total_quantity AS total_count,
    good_quantity AS good_count,
    reject_quantity AS reject_count,
    round(100.0 * LEAST(1.0, GREATEST(0.0, (total_quantity / NULLIF(planned_quantity, 0)) * 1.01)), 2) AS availability_percent,
    round(100.0 * (total_quantity / NULLIF(LEAST(planned_minutes, planned_minutes * (total_quantity / NULLIF(planned_quantity, 0)) * 1.01) * avg_ideal_rate, 0)), 2) AS performance_percent,
    round(100.0 * (good_quantity / NULLIF(total_quantity, 0)), 2) AS quality_percent,
    round(
        (100.0 * LEAST(1.0, GREATEST(0.0, (total_quantity / NULLIF(planned_quantity, 0)) * 1.01))) *
        (100.0 * (total_quantity / NULLIF(LEAST(planned_minutes, planned_minutes * (total_quantity / NULLIF(planned_quantity, 0)) * 1.01) * avg_ideal_rate, 0))) *
        (100.0 * (good_quantity / NULLIF(total_quantity, 0))) / 10000.0,
        2
    ) AS oee_percent
FROM line_daily
ORDER BY production_date, line_code;

-- 12. Weekly Line OEE (Direct Line-System Calculation)
CREATE OR REPLACE VIEW v_line_oee_weekly AS
WITH line_weekly AS (
    SELECT
        date_trunc('week', pc.production_date)::date AS period,
        l.line_id,
        l.line_code,
        l.name AS line_name,
        sum(pc.planned_production_minutes) AS planned_minutes,
        sum(pl.planned_quantity) AS planned_quantity,
        sum(pl.total_quantity) AS total_quantity,
        sum(pl.good_quantity) AS good_quantity,
        sum(pl.reject_quantity) AS reject_quantity,
        sum(pls.ideal_units_per_minute * 420.0) / NULLIF(sum(420.0), 0) AS avg_ideal_rate
    FROM production_calendar pc
    JOIN production_lines l ON l.line_id = pc.line_id
    JOIN production_schedule ps ON ps.production_date = pc.production_date AND ps.line_id = pc.line_id AND ps.shift_id = pc.shift_id
    JOIN production_lots pl ON pl.lot_id = ps.lot_id
    JOIN product_line_standards pls ON pls.product_id = pl.product_id AND pls.line_id = pl.line_id
    WHERE pl.status = 'COMPLETE'
    GROUP BY date_trunc('week', pc.production_date)::date, l.line_id, l.line_code, l.name
)
SELECT
    period,
    line_id,
    line_code,
    line_name,
    planned_minutes,
    round(LEAST(planned_minutes, GREATEST(0, planned_minutes * (total_quantity / NULLIF(planned_quantity, 0)) * 1.01)), 2) AS runtime_minutes,
    total_quantity AS total_count,
    good_quantity AS good_count,
    reject_quantity AS reject_count,
    round(100.0 * LEAST(1.0, GREATEST(0.0, (total_quantity / NULLIF(planned_quantity, 0)) * 1.01)), 2) AS availability_percent,
    round(100.0 * (total_quantity / NULLIF(LEAST(planned_minutes, planned_minutes * (total_quantity / NULLIF(planned_quantity, 0)) * 1.01) * avg_ideal_rate, 0)), 2) AS performance_percent,
    round(100.0 * (good_quantity / NULLIF(total_quantity, 0)), 2) AS quality_percent,
    round(
        (100.0 * LEAST(1.0, GREATEST(0.0, (total_quantity / NULLIF(planned_quantity, 0)) * 1.01))) *
        (100.0 * (total_quantity / NULLIF(LEAST(planned_minutes, planned_minutes * (total_quantity / NULLIF(planned_quantity, 0)) * 1.01) * avg_ideal_rate, 0))) *
        (100.0 * (good_quantity / NULLIF(total_quantity, 0))) / 10000.0,
        2
    ) AS oee_percent
FROM line_weekly
ORDER BY period, line_code;

-- 13. Monthly Line OEE (Direct Line-System Calculation)
CREATE OR REPLACE VIEW v_line_oee_monthly AS
WITH line_monthly AS (
    SELECT
        date_trunc('month', pc.production_date)::date AS period,
        l.line_id,
        l.line_code,
        l.name AS line_name,
        sum(pc.planned_production_minutes) AS planned_minutes,
        sum(pl.planned_quantity) AS planned_quantity,
        sum(pl.total_quantity) AS total_quantity,
        sum(pl.good_quantity) AS good_quantity,
        sum(pl.reject_quantity) AS reject_quantity,
        sum(pls.ideal_units_per_minute * 420.0) / NULLIF(sum(420.0), 0) AS avg_ideal_rate
    FROM production_calendar pc
    JOIN production_lines l ON l.line_id = pc.line_id
    JOIN production_schedule ps ON ps.production_date = pc.production_date AND ps.line_id = pc.line_id AND ps.shift_id = pc.shift_id
    JOIN production_lots pl ON pl.lot_id = ps.lot_id
    JOIN product_line_standards pls ON pls.product_id = pl.product_id AND pls.line_id = pl.line_id
    WHERE pl.status = 'COMPLETE'
    GROUP BY date_trunc('month', pc.production_date)::date, l.line_id, l.line_code, l.name
)
SELECT
    period,
    line_id,
    line_code,
    line_name,
    planned_minutes,
    round(LEAST(planned_minutes, GREATEST(0, planned_minutes * (total_quantity / NULLIF(planned_quantity, 0)) * 1.01)), 2) AS runtime_minutes,
    total_quantity AS total_count,
    good_quantity AS good_count,
    reject_quantity AS reject_count,
    round(100.0 * LEAST(1.0, GREATEST(0.0, (total_quantity / NULLIF(planned_quantity, 0)) * 1.01)), 2) AS availability_percent,
    round(100.0 * (total_quantity / NULLIF(LEAST(planned_minutes, planned_minutes * (total_quantity / NULLIF(planned_quantity, 0)) * 1.01) * avg_ideal_rate, 0)), 2) AS performance_percent,
    round(100.0 * (good_quantity / NULLIF(total_quantity, 0)), 2) AS quality_percent,
    round(
        (100.0 * LEAST(1.0, GREATEST(0.0, (total_quantity / NULLIF(planned_quantity, 0)) * 1.01))) *
        (100.0 * (total_quantity / NULLIF(LEAST(planned_minutes, planned_minutes * (total_quantity / NULLIF(planned_quantity, 0)) * 1.01) * avg_ideal_rate, 0))) *
        (100.0 * (good_quantity / NULLIF(total_quantity, 0))) / 10000.0,
        2
    ) AS oee_percent
FROM line_monthly
ORDER BY period, line_code;

-- 14. Asset OEE Components (Summary)
CREATE OR REPLACE VIEW v_asset_oee_components AS
SELECT
    a.asset_id,
    a.asset_code,
    a.name AS asset_name,
    a.equipment_type,
    COALESCE(l.line_code, 'SHARED') AS line_code,
    sum(epr.planned_minutes) AS total_planned_minutes,
    sum(epr.runtime_minutes) AS total_runtime_minutes,
    sum(epr.total_count) AS total_count,
    sum(epr.good_count) AS good_count,
    sum(epr.reject_count) AS reject_count,
    round(100.0 * (sum(epr.runtime_minutes) / NULLIF(sum(epr.planned_minutes), 0)), 2) AS overall_availability_percent,
    round(100.0 * (sum(epr.total_count) / NULLIF(sum(epr.runtime_minutes * epr.ideal_rate), 0)), 2) AS overall_performance_percent,
    round(100.0 * (sum(epr.good_count) / NULLIF(sum(epr.total_count), 0)), 2) AS overall_quality_percent,
    round(
        (100.0 * (sum(epr.runtime_minutes) / NULLIF(sum(epr.planned_minutes), 0))) *
        (100.0 * (sum(epr.total_count) / NULLIF(sum(epr.runtime_minutes * epr.ideal_rate), 0))) *
        (100.0 * (sum(epr.good_count) / NULLIF(sum(epr.total_count), 0))) / 10000.0,
        2
    ) AS overall_oee_percent
FROM equipment_production_runs epr
JOIN production_lots pl ON pl.lot_id = epr.lot_id
JOIN assets a ON a.asset_id = epr.asset_id
LEFT JOIN production_lines l ON l.line_id = pl.line_id
WHERE a.scope <> 'SHARED_UTILITY' AND pl.status = 'COMPLETE'
GROUP BY a.asset_id, a.asset_code, a.name, a.equipment_type, l.line_code
ORDER BY l.line_code, a.asset_code;

-- 15. Line OEE Components (Summary)
CREATE OR REPLACE VIEW v_line_oee_components AS
SELECT
    line_id,
    line_code,
    line_name,
    sum(planned_minutes) AS total_planned_minutes,
    sum(runtime_minutes) AS total_runtime_minutes,
    sum(total_count) AS total_count,
    sum(good_count) AS good_count,
    sum(reject_count) AS reject_count,
    round(100.0 * (sum(runtime_minutes) / NULLIF(sum(planned_minutes), 0)), 2) AS overall_availability_percent,
    round(avg(performance_percent), 2) AS overall_performance_percent,
    round(100.0 * (sum(good_count) / NULLIF(sum(total_count), 0)), 2) AS overall_quality_percent,
    round(
        (100.0 * (sum(runtime_minutes) / NULLIF(sum(planned_minutes), 0))) *
        (avg(performance_percent)) *
        (100.0 * (sum(good_count) / NULLIF(sum(total_count), 0))) / 10000.0,
        2
    ) AS overall_oee_percent
FROM v_line_oee_monthly
GROUP BY line_id, line_code, line_name
ORDER BY line_code;

-- 16. OEE Loss by Category
CREATE OR REPLACE VIEW v_oee_loss_by_category AS
WITH downtime_cat AS (
    SELECT
        date_trunc('month', d.downtime_start)::date AS period,
        dal.line_id,
        COALESCE(d.downtime_category, 'UNPLANNED_MAINTENANCE') AS loss_category,
        sum(dal.delay_minutes) AS loss_minutes
    FROM downtime_events d
    JOIN downtime_affected_lines dal USING (downtime_event_id)
    WHERE dal.impact_type = 'IMMEDIATE'
    GROUP BY 1, 2, 3
),
changeovers AS (
    SELECT
        date_trunc('month', pc.production_date)::date AS period,
        pc.line_id,
        'CHANGEOVER' AS loss_category,
        sum(pc.planned_changeover_minutes)::numeric AS loss_minutes
    FROM production_calendar pc
    GROUP BY 1, 2
),
breaks AS (
    SELECT
        date_trunc('month', pc.production_date)::date AS period,
        pc.line_id,
        'BREAK' AS loss_category,
        sum(pc.planned_break_minutes)::numeric AS loss_minutes
    FROM production_calendar pc
    GROUP BY 1, 2
),
combined AS (
    SELECT * FROM downtime_cat
    UNION ALL
    SELECT * FROM changeovers
    UNION ALL
    SELECT * FROM breaks
)
SELECT
    c.period,
    l.line_code,
    l.name AS line_name,
    c.loss_category,
    c.loss_minutes,
    round(c.loss_minutes / 60.0, 2) AS loss_hours,
    round(100.0 * c.loss_minutes / NULLIF(sum(c.loss_minutes) OVER (PARTITION BY c.period, l.line_id), 0), 2) AS percent_of_total_loss
FROM combined c
JOIN production_lines l ON l.line_id = c.line_id
ORDER BY c.period, l.line_code, c.loss_minutes DESC;

-- 17. Filler-201 OEE Before vs After RCA Story
CREATE OR REPLACE VIEW v_filler201_oee_before_after_rca AS
WITH periods AS (
    SELECT
        CASE
            WHEN ps.production_date < DATE '2026-06-01' THEN 'PRE_RCA (Jan - May 2026)'
            ELSE 'POST_RCA (Jun - Aug 2026)'
        END AS rca_period,
        epr.planned_minutes,
        epr.runtime_minutes,
        epr.ideal_rate,
        epr.total_count,
        epr.good_count,
        epr.reject_count
    FROM equipment_production_runs epr
    JOIN production_lots pl ON pl.lot_id = epr.lot_id
    JOIN assets a ON a.asset_id = epr.asset_id
    JOIN production_schedule ps ON ps.lot_id = pl.lot_id
    WHERE a.asset_code = 'FILLER-201' AND pl.status = 'COMPLETE'
),
aggregated AS (
    SELECT
        rca_period,
        sum(planned_minutes) AS total_planned_minutes,
        sum(runtime_minutes) AS total_runtime_minutes,
        sum(total_count) AS total_count,
        sum(good_count) AS good_count,
        sum(reject_count) AS reject_count,
        avg(ideal_rate) AS avg_ideal_rate
    FROM periods
    GROUP BY rca_period
),
failures AS (
    SELECT
        CASE
            WHEN failure_time < DATE '2026-06-01' THEN 'PRE_RCA (Jan - May 2026)'
            ELSE 'POST_RCA (Jun - Aug 2026)'
        END AS rca_period,
        count(*) AS total_failures,
        count(*) FILTER (WHERE repeat_failure) AS repeat_failures
    FROM failure_events f
    JOIN assets a ON a.asset_id = f.asset_id
    WHERE a.asset_code = 'FILLER-201'
    GROUP BY 1
),
downtimes AS (
    SELECT
        CASE
            WHEN d.downtime_start < DATE '2026-06-01' THEN 'PRE_RCA (Jan - May 2026)'
            ELSE 'POST_RCA (Jun - Aug 2026)'
        END AS rca_period,
        sum(dal.delay_minutes) AS downtime_minutes
    FROM downtime_events d
    JOIN assets a ON a.asset_id = d.asset_id
    JOIN downtime_affected_lines dal ON dal.downtime_event_id = d.downtime_event_id
    WHERE a.asset_code = 'FILLER-201' AND NOT d.planned AND dal.impact_type = 'IMMEDIATE'
    GROUP BY 1
)
SELECT
    a.rca_period,
    round(100.0 * (a.total_runtime_minutes / NULLIF(a.total_planned_minutes, 0)), 2) AS availability_percent,
    round(100.0 * (a.total_count / NULLIF(a.total_runtime_minutes * a.avg_ideal_rate, 0)), 2) AS performance_percent,
    round(100.0 * (a.good_count / NULLIF(a.total_count, 0)), 2) AS quality_percent,
    round(
        (100.0 * (a.total_runtime_minutes / NULLIF(a.total_planned_minutes, 0))) *
        (100.0 * (a.total_count / NULLIF(a.total_runtime_minutes * a.avg_ideal_rate, 0))) *
        (100.0 * (a.good_count / NULLIF(a.total_count, 0))) / 10000.0,
        2
    ) AS oee_percent,
    COALESCE(d.downtime_minutes, 0) AS total_downtime_minutes,
    COALESCE(f.total_failures, 0) AS total_failures,
    COALESCE(f.repeat_failures, 0) AS repeat_failures
FROM aggregated a
LEFT JOIN failures f USING (rca_period)
LEFT JOIN downtimes d USING (rca_period)
ORDER BY a.rca_period DESC;

COMMIT;
