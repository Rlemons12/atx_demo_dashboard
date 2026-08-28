BEGIN;

CREATE TYPE relationship_type AS ENUM ('DEDICATED', 'SIMULTANEOUS_DEPENDENCY', 'SCHEDULED_SHARED');
CREATE TYPE asset_scope AS ENUM ('DEDICATED_PRODUCTION', 'SHARED_PRODUCTION', 'SHARED_UTILITY');
CREATE TYPE pm_frequency AS ENUM ('WEEKLY', 'BIWEEKLY', 'MONTHLY', 'QUARTERLY', 'SEMIANNUAL');
CREATE TYPE priority_level AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL');
CREATE TYPE pm_execution_status AS ENUM ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');
CREATE TYPE work_type AS ENUM ('PREVENTIVE', 'CORRECTIVE', 'EMERGENCY', 'PREDICTIVE', 'SANITATION_FINDING', 'INSPECTION', 'PROJECT');
CREATE TYPE work_status AS ENUM ('REQUESTED', 'ACKNOWLEDGED', 'IN_PROGRESS', 'COMPLETED', 'CLOSED', 'CANCELLED');
CREATE TYPE inventory_transaction_type AS ENUM ('RECEIPT', 'ISSUE', 'ADJUSTMENT', 'RETURN');
CREATE TYPE rca_status AS ENUM ('OPEN', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');
CREATE TYPE action_type AS ENUM ('REPAIR', 'PM_REVISION', 'SPARE_PART_UPDATE', 'INSPECTION', 'TRAINING', 'ENGINEERING_CHANGE', 'OTHER');
CREATE TYPE finding_status AS ENUM ('OPEN', 'WORK_ORDER_CREATED', 'RESOLVED', 'CLOSED');
CREATE TYPE overtime_type AS ENUM ('PLANNED', 'REACTIVE');
CREATE TYPE project_status AS ENUM ('PROPOSED', 'APPROVED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');

CREATE TABLE sites (
    site_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    site_code text NOT NULL UNIQUE,
    name text NOT NULL,
    timezone text NOT NULL DEFAULT 'America/Chicago',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE production_lines (
    line_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    site_id bigint NOT NULL REFERENCES sites(site_id) ON DELETE RESTRICT,
    line_code text NOT NULL,
    name text NOT NULL,
    active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (site_id, line_code),
    UNIQUE (line_id, site_id)
);

CREATE TABLE shifts (
    shift_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    site_id bigint NOT NULL REFERENCES sites(site_id) ON DELETE RESTRICT,
    shift_code text NOT NULL,
    name text NOT NULL,
    function text NOT NULL CHECK (function IN ('PRODUCTION', 'SANITATION')),
    start_time time NOT NULL,
    end_time time NOT NULL,
    active boolean NOT NULL DEFAULT true,
    UNIQUE (site_id, shift_code)
);

CREATE TABLE employees (
    employee_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    site_id bigint NOT NULL REFERENCES sites(site_id) ON DELETE RESTRICT,
    employee_number text NOT NULL UNIQUE,
    first_name text NOT NULL,
    last_name text NOT NULL,
    job_title text NOT NULL,
    department text NOT NULL CHECK (department IN ('MAINTENANCE', 'PRODUCTION', 'SANITATION')),
    active boolean NOT NULL DEFAULT true,
    hired_on date,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE employee_shift_assignments (
    assignment_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id bigint NOT NULL REFERENCES employees(employee_id) ON DELETE CASCADE,
    shift_id bigint NOT NULL REFERENCES shifts(shift_id) ON DELETE CASCADE,
    is_primary boolean NOT NULL DEFAULT true,
    effective_from date NOT NULL DEFAULT CURRENT_DATE,
    effective_to date,
    CHECK (effective_to IS NULL OR effective_to >= effective_from),
    UNIQUE (employee_id, shift_id, effective_from)
);

CREATE TABLE assets (
    asset_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    site_id bigint NOT NULL REFERENCES sites(site_id) ON DELETE RESTRICT,
    asset_code text NOT NULL UNIQUE,
    name text NOT NULL,
    equipment_type text NOT NULL,
    scope asset_scope NOT NULL,
    manufacturer text,
    model text,
    serial_number text,
    commissioned_on date,
    active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE asset_line_relationships (
    relationship_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    asset_id bigint NOT NULL REFERENCES assets(asset_id) ON DELETE CASCADE,
    line_id bigint NOT NULL REFERENCES production_lines(line_id) ON DELETE CASCADE,
    relationship_type relationship_type NOT NULL,
    impact_priority smallint NOT NULL DEFAULT 1 CHECK (impact_priority BETWEEN 1 AND 5),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (asset_id, line_id)
);

CREATE TABLE asset_production_schedule (
    schedule_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    asset_id bigint NOT NULL REFERENCES assets(asset_id) ON DELETE CASCADE,
    line_id bigint NOT NULL REFERENCES production_lines(line_id) ON DELETE CASCADE,
    scheduled_start timestamptz NOT NULL,
    scheduled_end timestamptz NOT NULL,
    production_order text,
    status text NOT NULL DEFAULT 'SCHEDULED' CHECK (status IN ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
    CHECK (scheduled_end > scheduled_start),
    UNIQUE (asset_id, scheduled_start, scheduled_end)
);

CREATE TABLE asset_criticality (
    asset_criticality_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    asset_id bigint NOT NULL UNIQUE REFERENCES assets(asset_id) ON DELETE CASCADE,
    production_impact smallint NOT NULL CHECK (production_impact BETWEEN 1 AND 5),
    safety_impact smallint NOT NULL CHECK (safety_impact BETWEEN 1 AND 5),
    food_safety_impact smallint NOT NULL CHECK (food_safety_impact BETWEEN 1 AND 5),
    quality_impact smallint NOT NULL CHECK (quality_impact BETWEEN 1 AND 5),
    redundancy smallint NOT NULL CHECK (redundancy BETWEEN 1 AND 5),
    spare_parts_lead_time smallint NOT NULL CHECK (spare_parts_lead_time BETWEEN 1 AND 5),
    repair_difficulty smallint NOT NULL CHECK (repair_difficulty BETWEEN 1 AND 5),
    shared_line_impact smallint NOT NULL CHECK (shared_line_impact BETWEEN 1 AND 5),
    criticality_class text NOT NULL CHECK (criticality_class IN ('A', 'B', 'C', 'PLANT_CRITICAL')),
    rationale text NOT NULL,
    assessed_at timestamptz NOT NULL DEFAULT now(),
    CHECK (production_impact + safety_impact + food_safety_impact + quality_impact + redundancy + spare_parts_lead_time + repair_difficulty + shared_line_impact BETWEEN 8 AND 40)
);

CREATE TABLE pm_plans (
    pm_plan_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    asset_id bigint NOT NULL REFERENCES assets(asset_id) ON DELETE RESTRICT,
    pm_code text NOT NULL UNIQUE,
    frequency pm_frequency NOT NULL,
    frequency_days integer NOT NULL CHECK (frequency_days > 0),
    title text NOT NULL,
    estimated_minutes integer NOT NULL CHECK (estimated_minutes > 0),
    priority priority_level NOT NULL,
    requires_shutdown boolean NOT NULL DEFAULT false,
    safety_notes text,
    current_revision integer NOT NULL DEFAULT 1 CHECK (current_revision > 0),
    active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (asset_id, frequency)
);

CREATE TABLE pm_plan_revisions (
    pm_plan_id bigint NOT NULL REFERENCES pm_plans(pm_plan_id) ON DELETE CASCADE,
    revision_number integer NOT NULL CHECK (revision_number > 0),
    effective_from date NOT NULL,
    effective_to date,
    change_reason text NOT NULL,
    rca_event_id bigint,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (pm_plan_id, revision_number),
    CHECK (effective_to IS NULL OR effective_to >= effective_from)
);

CREATE TABLE pm_tasks (
    pm_task_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pm_plan_id bigint NOT NULL REFERENCES pm_plans(pm_plan_id) ON DELETE CASCADE,
    revision_number integer NOT NULL,
    sequence_number integer NOT NULL CHECK (sequence_number > 0),
    task_description text NOT NULL,
    requires_shutdown boolean NOT NULL DEFAULT false,
    safety_note text,
    active boolean NOT NULL DEFAULT true,
    FOREIGN KEY (pm_plan_id, revision_number) REFERENCES pm_plan_revisions(pm_plan_id, revision_number) ON DELETE CASCADE,
    UNIQUE (pm_plan_id, revision_number, sequence_number)
);

CREATE TABLE work_orders (
    work_order_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    work_order_number text NOT NULL UNIQUE,
    asset_id bigint REFERENCES assets(asset_id) ON DELETE RESTRICT,
    work_type work_type NOT NULL,
    priority priority_level NOT NULL,
    title text NOT NULL,
    description text,
    requested_at timestamptz NOT NULL,
    acknowledged_at timestamptz,
    work_started_at timestamptz,
    work_completed_at timestamptz,
    closed_at timestamptz,
    status work_status NOT NULL DEFAULT 'REQUESTED',
    emergency boolean NOT NULL DEFAULT false,
    planned boolean NOT NULL DEFAULT false,
    failure_code text,
    cause_code text,
    assigned_employee_id bigint REFERENCES employees(employee_id) ON DELETE SET NULL,
    labor_hours numeric(10,2) NOT NULL DEFAULT 0 CHECK (labor_hours >= 0),
    labor_cost numeric(12,2) NOT NULL DEFAULT 0 CHECK (labor_cost >= 0),
    parts_cost numeric(12,2) NOT NULL DEFAULT 0 CHECK (parts_cost >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (acknowledged_at IS NULL OR acknowledged_at >= requested_at),
    CHECK (work_started_at IS NULL OR work_started_at >= requested_at),
    CHECK (work_completed_at IS NULL OR (work_started_at IS NOT NULL AND work_completed_at >= work_started_at)),
    CHECK (closed_at IS NULL OR (work_completed_at IS NOT NULL AND closed_at >= work_completed_at)),
    CHECK (NOT emergency OR work_type = 'EMERGENCY')
);

CREATE TABLE pm_executions (
    pm_execution_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pm_plan_id bigint NOT NULL REFERENCES pm_plans(pm_plan_id) ON DELETE RESTRICT,
    revision_number integer NOT NULL,
    scheduled_date date NOT NULL,
    completed_date date,
    technician_id bigint REFERENCES employees(employee_id) ON DELETE SET NULL,
    status pm_execution_status NOT NULL DEFAULT 'SCHEDULED',
    work_order_id bigint UNIQUE REFERENCES work_orders(work_order_id) ON DELETE SET NULL,
    completion_notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    FOREIGN KEY (pm_plan_id, revision_number) REFERENCES pm_plan_revisions(pm_plan_id, revision_number) ON DELETE RESTRICT,
    UNIQUE (pm_plan_id, scheduled_date),
    CHECK (completed_date IS NULL OR completed_date >= scheduled_date),
    CHECK ((status = 'COMPLETED') = (completed_date IS NOT NULL))
);

CREATE TABLE downtime_events (
    downtime_event_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    asset_id bigint NOT NULL REFERENCES assets(asset_id) ON DELETE RESTRICT,
    work_order_id bigint REFERENCES work_orders(work_order_id) ON DELETE SET NULL,
    downtime_start timestamptz NOT NULL,
    downtime_end timestamptz,
    planned boolean NOT NULL,
    reason text NOT NULL,
    production_impact text NOT NULL CHECK (production_impact IN ('NONE', 'CURRENT_LINE', 'MULTIPLE_LINES', 'PLANT_WIDE', 'FUTURE_RISK')),
    estimated_delay_minutes integer NOT NULL DEFAULT 0 CHECK (estimated_delay_minutes >= 0),
    CHECK (downtime_end IS NULL OR downtime_end >= downtime_start)
);

CREATE TABLE downtime_affected_lines (
    downtime_event_id bigint NOT NULL REFERENCES downtime_events(downtime_event_id) ON DELETE CASCADE,
    line_id bigint NOT NULL REFERENCES production_lines(line_id) ON DELETE CASCADE,
    impact_type text NOT NULL CHECK (impact_type IN ('IMMEDIATE', 'FUTURE_RISK')),
    delay_minutes integer NOT NULL DEFAULT 0 CHECK (delay_minutes >= 0),
    PRIMARY KEY (downtime_event_id, line_id, impact_type)
);

CREATE TABLE failure_events (
    failure_event_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    asset_id bigint NOT NULL REFERENCES assets(asset_id) ON DELETE RESTRICT,
    work_order_id bigint REFERENCES work_orders(work_order_id) ON DELETE SET NULL,
    failure_time timestamptz NOT NULL,
    failure_mode text NOT NULL,
    production_stopped boolean NOT NULL,
    repeat_failure boolean NOT NULL DEFAULT false,
    notes text
);

CREATE TABLE rca_events (
    rca_event_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rca_number text NOT NULL UNIQUE,
    work_order_id bigint NOT NULL REFERENCES work_orders(work_order_id) ON DELETE RESTRICT,
    problem_statement text NOT NULL,
    root_cause text,
    analysis_method text NOT NULL,
    opened_at timestamptz NOT NULL,
    completed_at timestamptz,
    status rca_status NOT NULL DEFAULT 'OPEN',
    CHECK (completed_at IS NULL OR completed_at >= opened_at)
);

ALTER TABLE pm_plan_revisions ADD CONSTRAINT fk_pm_revision_rca
    FOREIGN KEY (rca_event_id) REFERENCES rca_events(rca_event_id) ON DELETE SET NULL;

CREATE TABLE corrective_actions (
    corrective_action_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rca_event_id bigint NOT NULL REFERENCES rca_events(rca_event_id) ON DELETE CASCADE,
    action_description text NOT NULL,
    owner_employee_id bigint REFERENCES employees(employee_id) ON DELETE SET NULL,
    due_date date NOT NULL,
    completed_date date,
    action_type action_type NOT NULL,
    verified_effectiveness boolean,
    verification_notes text
);

CREATE TABLE sanitation_findings (
    sanitation_finding_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    finding_number text NOT NULL UNIQUE,
    asset_id bigint REFERENCES assets(asset_id) ON DELETE RESTRICT,
    reported_by bigint NOT NULL REFERENCES employees(employee_id) ON DELETE RESTRICT,
    reported_at timestamptz NOT NULL,
    description text NOT NULL,
    priority priority_level NOT NULL,
    maintenance_required boolean NOT NULL,
    startup_risk boolean NOT NULL,
    work_order_id bigint REFERENCES work_orders(work_order_id) ON DELETE SET NULL,
    status finding_status NOT NULL DEFAULT 'OPEN'
);

CREATE TABLE parts (
    part_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    part_number text NOT NULL UNIQUE,
    description text NOT NULL,
    unit_cost numeric(12,2) NOT NULL CHECK (unit_cost >= 0),
    quantity_on_hand numeric(12,2) NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
    minimum_quantity numeric(12,2) NOT NULL DEFAULT 0 CHECK (minimum_quantity >= 0),
    maximum_quantity numeric(12,2) NOT NULL CHECK (maximum_quantity >= minimum_quantity),
    lead_time_days integer NOT NULL DEFAULT 0 CHECK (lead_time_days >= 0),
    critical_spare boolean NOT NULL DEFAULT false,
    unit_of_measure text NOT NULL DEFAULT 'EA',
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE asset_parts (
    asset_part_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    asset_id bigint NOT NULL REFERENCES assets(asset_id) ON DELETE CASCADE,
    part_id bigint NOT NULL REFERENCES parts(part_id) ON DELETE RESTRICT,
    quantity_required numeric(12,2) NOT NULL DEFAULT 1 CHECK (quantity_required > 0),
    critical_for_asset boolean NOT NULL DEFAULT false,
    notes text,
    UNIQUE (asset_id, part_id)
);

CREATE TABLE inventory_transactions (
    inventory_transaction_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    part_id bigint NOT NULL REFERENCES parts(part_id) ON DELETE RESTRICT,
    transaction_type inventory_transaction_type NOT NULL,
    quantity numeric(12,2) NOT NULL CHECK (quantity <> 0),
    transaction_at timestamptz NOT NULL DEFAULT now(),
    work_order_id bigint REFERENCES work_orders(work_order_id) ON DELETE SET NULL,
    reference text,
    notes text,
    CHECK ((transaction_type IN ('RECEIPT', 'RETURN') AND quantity > 0) OR
           (transaction_type = 'ISSUE' AND quantity < 0) OR
           transaction_type = 'ADJUSTMENT')
);

CREATE TABLE skills (
    skill_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    skill_code text NOT NULL UNIQUE,
    name text NOT NULL,
    description text,
    critical_skill boolean NOT NULL DEFAULT false
);

CREATE TABLE employee_skills (
    employee_id bigint NOT NULL REFERENCES employees(employee_id) ON DELETE CASCADE,
    skill_id bigint NOT NULL REFERENCES skills(skill_id) ON DELETE CASCADE,
    proficiency_level smallint NOT NULL CHECK (proficiency_level BETWEEN 1 AND 4),
    assessed_on date NOT NULL DEFAULT CURRENT_DATE,
    expires_on date,
    PRIMARY KEY (employee_id, skill_id),
    CHECK (expires_on IS NULL OR expires_on >= assessed_on)
);

CREATE TABLE maintenance_costs (
    maintenance_cost_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    work_order_id bigint REFERENCES work_orders(work_order_id) ON DELETE SET NULL,
    asset_id bigint REFERENCES assets(asset_id) ON DELETE RESTRICT,
    employee_id bigint REFERENCES employees(employee_id) ON DELETE SET NULL,
    cost_date date NOT NULL,
    cost_category text NOT NULL CHECK (cost_category IN ('LABOR', 'PARTS', 'CONTRACTOR', 'OVERTIME', 'OTHER')),
    amount numeric(12,2) NOT NULL CHECK (amount >= 0),
    overtime_type overtime_type,
    description text,
    CHECK ((cost_category = 'OVERTIME') OR overtime_type IS NULL)
);

CREATE TABLE capital_projects (
    capital_project_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_code text NOT NULL UNIQUE,
    site_id bigint NOT NULL REFERENCES sites(site_id) ON DELETE RESTRICT,
    asset_id bigint REFERENCES assets(asset_id) ON DELETE SET NULL,
    name text NOT NULL,
    description text,
    status project_status NOT NULL DEFAULT 'PROPOSED',
    estimated_cost numeric(14,2) NOT NULL CHECK (estimated_cost >= 0),
    approved_budget numeric(14,2) CHECK (approved_budget >= 0),
    estimated_annual_savings numeric(14,2) CHECK (estimated_annual_savings >= 0),
    planned_start date,
    planned_end date,
    actual_end date,
    CHECK (planned_end IS NULL OR planned_start IS NULL OR planned_end >= planned_start)
);

CREATE TABLE kpi_targets (
    kpi_target_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    site_id bigint NOT NULL REFERENCES sites(site_id) ON DELETE CASCADE,
    kpi_code text NOT NULL,
    display_name text NOT NULL,
    comparison_operator text NOT NULL CHECK (comparison_operator IN ('>=', '<=', '<', '>')),
    target_value numeric(12,4) NOT NULL,
    unit text NOT NULL,
    effective_from date NOT NULL,
    effective_to date,
    CHECK (effective_to IS NULL OR effective_to >= effective_from),
    UNIQUE (site_id, kpi_code, effective_from)
);

CREATE INDEX idx_asset_relationship_line ON asset_line_relationships(line_id, relationship_type);
CREATE INDEX idx_asset_schedule_window ON asset_production_schedule(asset_id, scheduled_start, scheduled_end);
CREATE INDEX idx_pm_execution_due ON pm_executions(status, scheduled_date);
CREATE INDEX idx_work_orders_asset_requested ON work_orders(asset_id, requested_at);
CREATE INDEX idx_work_orders_status_priority ON work_orders(status, priority);
CREATE INDEX idx_downtime_asset_start ON downtime_events(asset_id, downtime_start);
CREATE INDEX idx_failure_asset_time ON failure_events(asset_id, failure_time);
CREATE INDEX idx_corrective_actions_due ON corrective_actions(completed_date, due_date);
CREATE INDEX idx_sanitation_open ON sanitation_findings(status, startup_risk);
CREATE INDEX idx_inventory_part_time ON inventory_transactions(part_id, transaction_at);
CREATE INDEX idx_maintenance_cost_date ON maintenance_costs(cost_date, cost_category);

COMMENT ON TABLE asset_line_relationships IS 'Relational production dependencies; dashboards derive line impact from these rows.';
COMMENT ON TABLE pm_plan_revisions IS 'Preserves PM content revisions, including changes resulting from RCA.';
COMMENT ON TABLE downtime_affected_lines IS 'Optional event-specific line impact; asset relationships remain the default dependency source.';
COMMENT ON COLUMN asset_criticality.redundancy IS 'Risk score: 1 means strong redundancy, 5 means no practical redundancy.';

COMMIT;
