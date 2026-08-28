BEGIN;

CREATE TABLE condition_measurements (
    condition_measurement_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    asset_id bigint NOT NULL REFERENCES assets(asset_id) ON DELETE CASCADE,
    measurement_type text NOT NULL CHECK (measurement_type IN ('VIBRATION', 'DISCHARGE_TEMPERATURE', 'MOTOR_CURRENT', 'DISCHARGE_PRESSURE', 'OPERATING_HOURS')),
    measured_at timestamptz NOT NULL,
    numeric_value numeric(14,3) NOT NULL,
    unit text NOT NULL,
    warning_threshold numeric(14,3),
    alarm_threshold numeric(14,3),
    threshold_direction text NOT NULL DEFAULT 'HIGH' CHECK (threshold_direction IN ('HIGH', 'LOW')),
    source text NOT NULL DEFAULT 'MANUAL_ROUTE',
    notes text,
    UNIQUE (asset_id, measurement_type, measured_at)
);

CREATE INDEX idx_condition_asset_type_time
    ON condition_measurements(asset_id, measurement_type, measured_at);

COMMENT ON TABLE condition_measurements IS 'Normalized predictive-maintenance readings used for Grafana time-series analysis.';

COMMIT;
