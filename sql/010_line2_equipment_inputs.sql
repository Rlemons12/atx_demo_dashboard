BEGIN;

-- Milestone 4 convention:
-- Calendar time = elapsed wall-clock time.
-- Scheduled production = scheduled shift minutes less planned breaks. Planned breaks
-- retain the legacy project convention and are outside the OEE denominator.
-- Changeover remains INSIDE scheduled production and is a planned production loss.
-- Sanitation, planned maintenance outside production, and no-schedule time reduce
-- Asset Utilization but do not directly reduce OEE Availability.

CREATE TABLE stop_reason_definitions (
    stop_reason_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    stop_reason_code text NOT NULL UNIQUE,
    display_name text NOT NULL,
    loss_category text NOT NULL CHECK (loss_category IN (
        'PLANNED','EQUIPMENT_MAINTENANCE','PROCESS','PRODUCTION_DEPENDENCY',
        'MATERIAL','QUALITY','SAFETY','OPERATIONS','UNKNOWN'
    )),
    responsible_function text NOT NULL CHECK (responsible_function IN (
        'MAINTENANCE','OPERATIONS','QUALITY','SANITATION','MATERIALS',
        'SCHEDULING','SAFETY','SHARED / CROSS_FUNCTIONAL','UNKNOWN'
    )),
    planned boolean NOT NULL DEFAULT false,
    maintenance_related boolean NOT NULL DEFAULT false,
    automatic_detection_allowed boolean NOT NULL DEFAULT true,
    default_priority smallint NOT NULL CHECK (default_priority BETWEEN 1 AND 100),
    description text NOT NULL,
    active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE equipment_sensors (
    sensor_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sensor_code text NOT NULL UNIQUE,
    asset_id bigint NOT NULL REFERENCES assets(asset_id) ON DELETE RESTRICT,
    sensor_type text NOT NULL,
    engineering_unit text,
    functional_class text NOT NULL,
    description text NOT NULL,
    active boolean NOT NULL DEFAULT true,
    source_type text NOT NULL DEFAULT 'SYNTHETIC_DEMO' CHECK (source_type IN ('SYNTHETIC_DEMO','PLC','MANUAL','SYSTEM')),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (asset_id, functional_class, sensor_code)
);

CREATE TABLE sensor_readings (
    reading_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sensor_id bigint NOT NULL REFERENCES equipment_sensors(sensor_id) ON DELETE CASCADE,
    observed_at timestamptz NOT NULL,
    numeric_value numeric(16,4),
    discrete_value text,
    quality_status text NOT NULL DEFAULT 'GOOD' CHECK (quality_status IN ('GOOD','UNCERTAIN','BAD')),
    lot_id bigint REFERENCES production_lots(lot_id) ON DELETE SET NULL,
    shift_id bigint REFERENCES shifts(shift_id) ON DELETE SET NULL,
    source_event_id bigint,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (numeric_value IS NOT NULL OR discrete_value IS NOT NULL),
    UNIQUE (sensor_id, observed_at)
);

CREATE TABLE equipment_state_events (
    state_event_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    asset_id bigint NOT NULL REFERENCES assets(asset_id) ON DELETE RESTRICT,
    lot_id bigint REFERENCES production_lots(lot_id) ON DELETE SET NULL,
    shift_id bigint REFERENCES shifts(shift_id) ON DELETE SET NULL,
    state_code text NOT NULL CHECK (state_code IN ('RUNNING','STOPPED','FAULTED','STARVED','BLOCKED','CHANGEOVER','PLANNED_STOP','IDLE')),
    start_time timestamptz NOT NULL,
    end_time timestamptz NOT NULL,
    primary_stop_reason_id bigint REFERENCES stop_reason_definitions(stop_reason_id) ON DELETE RESTRICT,
    reason_source text CHECK (reason_source IN ('SENSOR_INFERRED','PLC_CODE','SCHEDULE_INFERRED','SYSTEM_RULE','OPERATOR_SELECTED','MAINTENANCE_SELECTED','MANUAL_OVERRIDE')),
    reason_confidence numeric(3,2) CHECK (reason_confidence BETWEEN 0 AND 1),
    inferred_stop_reason_id bigint REFERENCES stop_reason_definitions(stop_reason_id) ON DELETE RESTRICT,
    inferred_reason_source text,
    inferred_reason_confidence numeric(3,2) CHECK (inferred_reason_confidence BETWEEN 0 AND 1),
    corrected_by_employee_id bigint REFERENCES employees(employee_id) ON DELETE SET NULL,
    corrected_at timestamptz,
    linked_downtime_event_id bigint REFERENCES downtime_events(downtime_event_id) ON DELETE SET NULL,
    linked_work_order_id bigint REFERENCES work_orders(work_order_id) ON DELETE SET NULL,
    evidence jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (end_time > start_time),
    CHECK ((state_code = 'RUNNING' AND primary_stop_reason_id IS NULL) OR state_code <> 'RUNNING'),
    UNIQUE (asset_id, start_time, end_time)
);

COMMENT ON TABLE stop_reason_definitions IS 'Normalized primary stop-reason taxonomy. Responsible function supports routing and analysis, never blame.';
COMMENT ON TABLE equipment_sensors IS 'Line 2 synthetic sensor/input master; no real PLC, OPC-UA, or MQTT connectivity is implied.';
COMMENT ON TABLE sensor_readings IS 'Deterministic synthetic observations. Change/event signals and periodic analog/counter samples support Grafana trends.';
COMMENT ON TABLE equipment_state_events IS 'Non-overlapping Line 2 equipment state intervals. Exactly one primary reason owns stopped minutes; inferred fields preserve audit history after correction.';
COMMENT ON COLUMN equipment_state_events.evidence IS 'Sensor/schedule evidence used by deterministic classification precedence: calendar/planned states, safety, faults, jams, downstream, upstream, material/quality/operator, unclassified.';

CREATE INDEX idx_sensor_readings_sensor_time ON sensor_readings(sensor_id, observed_at);
CREATE INDEX idx_equipment_sensors_asset ON equipment_sensors(asset_id, active);
CREATE INDEX idx_equipment_state_asset_time ON equipment_state_events(asset_id, start_time, end_time);
CREATE INDEX idx_equipment_state_reason_time ON equipment_state_events(primary_stop_reason_id, start_time);
CREATE INDEX idx_equipment_state_downtime ON equipment_state_events(linked_downtime_event_id) WHERE linked_downtime_event_id IS NOT NULL;

COMMIT;
