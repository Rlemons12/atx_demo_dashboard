BEGIN;

-- 1. Product Master
CREATE TABLE products (
    product_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_code text NOT NULL UNIQUE,
    product_name text NOT NULL,
    description text,
    active boolean NOT NULL DEFAULT true,
    default_batch_size numeric(12,2) NOT NULL CHECK (default_batch_size > 0),
    units_per_case integer NOT NULL DEFAULT 12 CHECK (units_per_case > 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE products IS 'Master catalog of food products / SKUs manufactured at ATX demonstration plant.';

-- 2. Product-Line Performance Standards
CREATE TABLE product_line_standards (
    standard_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id bigint NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    line_id bigint NOT NULL REFERENCES production_lines(line_id) ON DELETE CASCADE,
    ideal_units_per_minute numeric(10,2) NOT NULL CHECK (ideal_units_per_minute > 0),
    expected_yield_pct numeric(5,2) NOT NULL DEFAULT 100.00 CHECK (expected_yield_pct BETWEEN 50 AND 100),
    standard_changeover_minutes integer NOT NULL DEFAULT 30 CHECK (standard_changeover_minutes >= 0),
    active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (product_id, line_id)
);

COMMENT ON TABLE product_line_standards IS 'Line-specific performance standards and ideal cycle rates for OEE calculations.';

-- 3. Production Calendar / Planned Production Time
CREATE TABLE production_calendar (
    calendar_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    production_date date NOT NULL,
    shift_id bigint NOT NULL REFERENCES shifts(shift_id) ON DELETE CASCADE,
    line_id bigint NOT NULL REFERENCES production_lines(line_id) ON DELETE CASCADE,
    scheduled_minutes integer NOT NULL DEFAULT 480 CHECK (scheduled_minutes > 0),
    planned_break_minutes integer NOT NULL DEFAULT 30 CHECK (planned_break_minutes >= 0),
    planned_changeover_minutes integer NOT NULL DEFAULT 30 CHECK (planned_changeover_minutes >= 0),
    planned_production_minutes integer NOT NULL CHECK (planned_production_minutes > 0),
    active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (production_date, shift_id, line_id),
    CHECK (planned_production_minutes = scheduled_minutes - planned_break_minutes - planned_changeover_minutes)
);

COMMENT ON TABLE production_calendar IS 'Operating schedule and planned production minutes per line per shift (OEE Availability denominator).';

-- 4. Production Lots
CREATE TABLE production_lots (
    lot_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lot_number text NOT NULL UNIQUE,
    product_id bigint NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    line_id bigint NOT NULL REFERENCES production_lines(line_id) ON DELETE RESTRICT,
    planned_start timestamptz NOT NULL,
    planned_end timestamptz NOT NULL,
    actual_start timestamptz,
    actual_end timestamptz,
    planned_quantity numeric(12,2) NOT NULL CHECK (planned_quantity > 0),
    total_quantity numeric(12,2) NOT NULL DEFAULT 0 CHECK (total_quantity >= 0),
    good_quantity numeric(12,2) NOT NULL DEFAULT 0 CHECK (good_quantity >= 0),
    reject_quantity numeric(12,2) NOT NULL DEFAULT 0 CHECK (reject_quantity >= 0),
    status text NOT NULL CHECK (status IN ('PLANNED', 'READY', 'RUNNING', 'PAUSED', 'COMPLETE', 'CANCELLED')),
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (planned_end > planned_start),
    CHECK (actual_end IS NULL OR (actual_start IS NOT NULL AND actual_end >= actual_start)),
    CHECK (good_quantity + reject_quantity <= total_quantity OR total_quantity = 0)
);

CREATE INDEX idx_production_lots_line_status ON production_lots(line_id, status);
CREATE INDEX idx_production_lots_planned_start ON production_lots(planned_start);

COMMENT ON TABLE production_lots IS 'Normalized production lots tracking planned vs actual times, counts, and status.';

-- 5. Production Lot Events
CREATE TABLE production_lot_events (
    lot_event_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lot_id bigint NOT NULL REFERENCES production_lots(lot_id) ON DELETE CASCADE,
    event_type text NOT NULL CHECK (event_type IN ('CREATED', 'READY', 'STARTED', 'PAUSED', 'RESUMED', 'COMPLETED', 'CANCELLED')),
    event_timestamp timestamptz NOT NULL,
    notes text
);

CREATE INDEX idx_lot_events_lot_id ON production_lot_events(lot_id, event_timestamp);

COMMENT ON TABLE production_lot_events IS 'Lifecycle event log for production lots.';

-- 6. Production Schedule
CREATE TABLE production_schedule (
    schedule_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    production_date date NOT NULL,
    shift_id bigint NOT NULL REFERENCES shifts(shift_id) ON DELETE CASCADE,
    line_id bigint NOT NULL REFERENCES production_lines(line_id) ON DELETE CASCADE,
    lot_id bigint NOT NULL REFERENCES production_lots(lot_id) ON DELETE CASCADE,
    scheduled_start timestamptz NOT NULL,
    scheduled_end timestamptz NOT NULL,
    sequence_number integer NOT NULL CHECK (sequence_number > 0),
    schedule_status text NOT NULL DEFAULT 'SCHEDULED' CHECK (schedule_status IN ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'DELAYED', 'CANCELLED')),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (production_date, shift_id, line_id, sequence_number),
    CHECK (scheduled_end > scheduled_start)
);

CREATE INDEX idx_prod_schedule_date_line ON production_schedule(production_date, line_id, sequence_number);

COMMENT ON TABLE production_schedule IS 'Sequence and timeline of production lots scheduled per line and shift.';

-- 7. Lot-Asset Relationships
CREATE TABLE production_lot_assets (
    lot_asset_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lot_id bigint NOT NULL REFERENCES production_lots(lot_id) ON DELETE CASCADE,
    asset_id bigint NOT NULL REFERENCES assets(asset_id) ON DELETE RESTRICT,
    sequence_number integer NOT NULL DEFAULT 1,
    planned_start timestamptz NOT NULL,
    planned_end timestamptz NOT NULL,
    actual_start timestamptz,
    actual_end timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (lot_id, asset_id),
    CHECK (planned_end > planned_start),
    CHECK (actual_end IS NULL OR (actual_start IS NOT NULL AND actual_end >= actual_start))
);

CREATE INDEX idx_lot_assets_asset_time ON production_lot_assets(asset_id, planned_start, planned_end);

COMMENT ON TABLE production_lot_assets IS 'Equipment allocated to each production lot, supporting shared asset arbitration.';

-- 8. Employee Schedules
CREATE TABLE employee_schedules (
    employee_schedule_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id bigint NOT NULL REFERENCES employees(employee_id) ON DELETE CASCADE,
    schedule_date date NOT NULL,
    shift_id bigint NOT NULL REFERENCES shifts(shift_id) ON DELETE CASCADE,
    line_id bigint REFERENCES production_lines(line_id) ON DELETE SET NULL,
    asset_id bigint REFERENCES assets(asset_id) ON DELETE SET NULL,
    scheduled_start timestamptz NOT NULL,
    scheduled_end timestamptz NOT NULL,
    assigned_role text NOT NULL,
    overtime_type overtime_type,
    status text NOT NULL DEFAULT 'SCHEDULED' CHECK (status IN ('SCHEDULED', 'CONFIRMED', 'COMPLETED', 'ABSENT', 'REASSIGNED')),
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (scheduled_end > scheduled_start),
    UNIQUE (employee_id, schedule_date, scheduled_start)
);

CREATE INDEX idx_emp_schedules_date_shift ON employee_schedules(schedule_date, shift_id, employee_id);

COMMENT ON TABLE employee_schedules IS 'Shift and line staffing schedules for production, maintenance, and sanitation.';

-- 9. Equipment Production Runs (OEE Component Store)
CREATE TABLE equipment_production_runs (
    run_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lot_id bigint NOT NULL REFERENCES production_lots(lot_id) ON DELETE CASCADE,
    asset_id bigint NOT NULL REFERENCES assets(asset_id) ON DELETE RESTRICT,
    planned_minutes numeric(10,2) NOT NULL CHECK (planned_minutes >= 0),
    runtime_minutes numeric(10,2) NOT NULL CHECK (runtime_minutes >= 0),
    ideal_rate numeric(10,2) NOT NULL CHECK (ideal_rate > 0),
    total_count numeric(12,2) NOT NULL DEFAULT 0 CHECK (total_count >= 0),
    good_count numeric(12,2) NOT NULL DEFAULT 0 CHECK (good_count >= 0),
    reject_count numeric(12,2) NOT NULL DEFAULT 0 CHECK (reject_count >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (lot_id, asset_id),
    CHECK (good_count + reject_count <= total_count OR total_count = 0)
);

CREATE INDEX idx_equip_runs_asset_lot ON equipment_production_runs(asset_id, lot_id);

COMMENT ON TABLE equipment_production_runs IS 'Execution metrics per asset per lot used to compute equipment-level OEE.';

-- 10. Downtime Category Extension
ALTER TABLE downtime_events
    ADD COLUMN IF NOT EXISTS downtime_category text
    CHECK (downtime_category IS NULL OR downtime_category IN (
        'UNPLANNED_MAINTENANCE', 'PLANNED_MAINTENANCE', 'CHANGEOVER',
        'SANITATION', 'MATERIAL_SHORTAGE', 'QUALITY_HOLD',
        'OPERATOR_DELAY', 'BREAK', 'NO_SCHEDULE'
    ));

-- Backfill existing historical downtime events with category
UPDATE downtime_events
SET downtime_category = CASE
    WHEN planned THEN 'PLANNED_MAINTENANCE'
    ELSE 'UNPLANNED_MAINTENANCE'
END
WHERE downtime_category IS NULL;

COMMIT;
