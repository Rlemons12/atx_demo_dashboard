# ATX Maintenance Manager Demo

This project provides a PostgreSQL and Grafana interview demonstration for a fictional two-line food manufacturing maintenance operation. The design source of truth is [documentation/atx_demo_dashboard.md](documentation/atx_demo_dashboard.md).

## Guided setup using a supplied .env

For a new named copy of the demo, place the supplied `.env` beside `setup.ps1` and double-click `setup.cmd`. Alternatively, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1
```

The setup asks what to install, then what to call it:

| Choice | Result | Required credentials/tools |
| --- | --- | --- |
| Both | New named database with demo tables/data, plus a Grafana folder, datasource, and five linked dashboards | PostgreSQL credentials with database-creation permission, `psql`, and Grafana URL/token with create permissions |
| Grafana only | Datasource and five dashboards connected to the existing `POSTGRES_DB`; no database changes | PostgreSQL host/user/password/database and Grafana URL/token; no `psql` needed |
| Database only | New named database with all demo tables, data, and views | PostgreSQL credentials with database-creation permission and `psql`; no Grafana credentials needed |

For example, `Interview Demo` creates `demo_interview_demo` in Both or Database mode. Grafana mode uses `POSTGRES_DB` from `.env` instead, so you can connect dashboards to a database created earlier. The existing database must already contain the project's demo tables and views. Database-only completion prints the `POSTGRES_DB` value to use when setting up Grafana later.

Grafana modes use the existing instance in `GRAFANA_URL`. Setup does not install Grafana or PostgreSQL. Grafana must be able to reach PostgreSQL. Database setup runs all 15 migrations/seeds and five validation suites; the ATX demonstration content stays the same. `DATABASE_URL_UNPOOLED`, when supplied, provides the direct migration connection and must point to the same PostgreSQL server/branch as the `POSTGRES_*` datasource settings. It is ignored in Grafana-only mode. Remote connections default to SSL `require`; set `POSTGRES_SSLMODE` if needed.

Database creation refuses an existing target, and Grafana creation refuses matching resource UIDs. The supplied `.env` and source dashboards are preserved. Partial failures leave created resources for inspection; setup does not automatically delete or resume them.

Preview locally without connecting or creating resources:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1 -Name "Interview Demo" -Plan
```

For an unattended setup, use `-Name "Interview Demo" -Mode Both -Yes`. `-Mode Grafana` and `-Mode Database` select the individual components. Preview and unattended runs default to Both when `-Mode` is omitted. To validate the setup code without live services, run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-setup.ps1`.

## Existing local setup prerequisites

- PostgreSQL 17 or a compatible supported PostgreSQL release
- PostgreSQL command-line tools (`psql`, `createdb`, and `dropdb`) on `PATH`
- Windows PowerShell 5.1 or PowerShell 7+
- An existing project-root `.env` with credentials authorized to create the dedicated database
- Grafana 13.0.2 installed at `C:\Program Files\GrafanaLabs\grafana` for the validated local startup path

Copy `.env.example` only when preparing a new environment. Never replace a working `.env` or commit it.

```dotenv
POSTGRES_USER=replace_me
POSTGRES_PASSWORD=replace_me
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=atx_demo_dashboard
POSTGRES_SCHEMA=public
```

`POSTGRES_DB` and `POSTGRES_SCHEMA` are optional. Their safe project defaults are `atx_demo_dashboard` and `public`.

## Complete rebuild

From the project root:

```powershell
.\scripts\validate-environment.ps1
.\scripts\rebuild-database.ps1 -ConfirmRebuild
```

The guarded rebuild creates the Milestone 1 foundation, validates it, applies the deterministic January–August 2026 history, creates trend views, applies Milestone 2.5 production and OEE schema and deterministic seed data, and runs all validation suites.

For a database that already contains Milestones 1 and 2:

```powershell
.\scripts\seed-production.ps1
.\scripts\validate-milestone2_5.ps1
```

## Rebuild the project database

This deletes only the explicitly guarded `atx_demo_dashboard` database and recreates it:

```powershell
.\scripts\rebuild-database.ps1 -ConfirmRebuild
```

The rebuild script refuses any database name other than `atx_demo_dashboard`.

## Grafana

To refresh the project dashboard configurations from the Grafana instance configured in `.env`, set `GRAFANA_URL` and `GRAFANA_SERVICE_ACCOUNT_TOKEN`, then run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/export-grafana-dashboards.ps1
```

The exporter discovers dashboards using paginated, read-only API requests and downloads those with an `atx-` UID prefix. Grafana Cloud billing, usage, incident, and platform-monitoring dashboards are excluded because they are unrelated to this demo. It updates `grafana/dashboards` by UID, preserves existing filenames, and retains local dashboards absent from the remote listing. All downloads are validated before writing. Numeric dashboard IDs are cleared for provisioning; queries, UIDs, versions, and datasource references remain as exported. `grafana/dashboard-export.json` records the source, export time, and original folder metadata. The local provider places these dashboards in its configured ATX Maintenance Demo folder; remote folders are not recreated. Referenced datasources and plugins must be available on the destination instance. The token is never written into the export metadata.

The project uses the installed Grafana binary but keeps its runtime database, logs, plugins, and provisioning isolated under the ignored `.grafana` directory. PostgreSQL credentials are supplied to Grafana only through the startup process environment.

```powershell
.\scripts\start-grafana.ps1
.\scripts\validate-grafana.ps1
.\scripts\test-ai-summary.ps1
```

## Milestone 4 — Line 2 sensor-to-OEE demonstration

Milestone 4 instruments only `MIXER-201`, `CONVEYOR-201`, `FILLER-201`, and `LABELER-201` in depth. Deterministic PostgreSQL telemetry resolves into auditable states and primary Stop Reason Tags, then into Equipment OEE and Loss Analysis. Line 2 OEE is independently calculated from line time, product-specific rate, and line counts; it is never the average of machine OEE percentages.

The aligned terms are Asset Utilization / Scheduled Utilization, Equipment OEE, Line OEE, and Loss Analysis—not the earlier draft labels “OEE1” and “OEE2.” Asset Utilization is Scheduled Production Time / Total Calendar Time and is not OEE. OEE is Availability × Performance / Speed × Quality. Loss Analysis separately explains scheduled capacity, stop, unplanned-maintenance, speed, and quality losses; it is not multiplied into OEE.

Planned breaks preserve the existing convention and are outside Scheduled Production Time. Planned changeover is inside Scheduled Production Time and visible as planned production loss. Sanitation, outside-schedule planned maintenance, and no-schedule time reduce utilization but not OEE Availability. `AIR-COMP-001` remains a shared utility and is excluded from piece-rate OEE.

Apply or validate Milestone 4 on an existing database:

```powershell
.\scripts\seed-line2-equipment-inputs.ps1
.\scripts\validate-milestone4.ps1
.\scripts\validate-grafana.ps1
.\scripts\test-ai-summary.ps1
```

The guarded `rebuild-database.ps1 -ConfirmRebuild` command also applies and validates Milestone 4 after Milestone 2.5.

## Current demo operating state

All panels labeled current, active, or latest use one PostgreSQL-owned demonstration clock: `INTERVIEW_DEMO` at **2026-08-28 10:00:00 America/Chicago**. They do not use `NOW()`, browser time, or the workstation clock. This keeps the interview scenario stable and repeatable whenever Grafana is opened.

The scenario is hypothetical and is not actual ATX production data, but every displayed value is read from relational PostgreSQL rows. At the anchor, Line 1 runs `ATX-20260828-L1-001` (Spicy Sauce), Line 2 runs `ATX-20260828-L2-001` (BBQ Blend), Production Shift A has its confirmed lead, two line operators, and maintenance technician, and the four dedicated Line 2 assets have current state and sensor observations. Historical January–August 2026 trends remain event-time based and are not rewritten around the anchor.

Apply or validate the current scenario on an existing Milestone 4 database:

```powershell
.\scripts\seed-current-demo-state.ps1
.\scripts\validate-current-demo-state.ps1
```

The semantic views `v_demo_context_active`, `v_current_production_status`, `v_current_line1_production_status`, `v_current_line2_production_status`, `v_current_shift_staffing`, `v_current_equipment_state`, `v_current_sensor_state`, and `v_current_month_schedule_adherence` derive current-state meaning from `demo_context.anchor_timestamp`.

> This dashboard is reading real rows from the PostgreSQL demo database. For the interview I use a fixed demo timestamp so the operating state is repeatable and does not depend on when I open the dashboard. The scenario is hypothetical, but the database relationships, calculations, drill-downs, and operating workflow are real.

Open Equipment OEE Detail (Filler-201 default): <http://127.0.0.1:3001/d/atx-equipment-oee-detail/equipment-oee-detail?var-asset=FILLER-201>

Filler-201 is the primary drill-down: photoeye evidence → stopped/faulted state → Photoeye Fault → downtime → work order → failure mode → RCA → bracket/locking corrective action → weekly PM revision → lower post-RCA stop loss. Conveyor-201 provides the secondary belt-tracking story.

Interview flow: start at VP Operations Overview, open Production & OEE Performance, show the independently calculated Line 2 OEE and four equipment contributors, then click Filler-201. Show raw time/rate/count/quality inputs; scheduled versus unscheduled time; Utilization, Availability, Performance, Quality, and OEE; separate stop/speed/quality losses; the photoeye Pareto; and the downtime-to-PM trace. Show post-RCA improvement, then return to Line 2 and the plant operations rollup without calling an average of percentages “Plant OEE.”

> We are not just showing an OEE percentage. We can trace the line KPI all the way back to the machine inputs, the specific losses, and the maintenance actions that change the result.

## Grafana panel reference

For a panel-by-panel explanation of every dashboard—including visualization type, calculation/query logic, interpretation, management significance, PostgreSQL source, variables, links, and recommended interview navigation—see [Grafana Dashboard Panel Guide](documentation/grafana_dashboard_panel_guide.md).

Open:

- VP Operations Overview: <http://127.0.0.1:3001/d/atx-vp-operations/vp-operations-overview>
- Maintenance Reliability: <http://127.0.0.1:3001/d/atx-maintenance-reliability/maintenance-reliability>
- Staffing, Sanitation & Operational Risk: <http://127.0.0.1:3001/d/atx-operational-risk/staffing-sanitation-and-operational-risk>
- Production & OEE Performance: <http://127.0.0.1:3001/d/atx-production-oee/production-and-oee-performance>

The project instance is bound to loopback and permits anonymous Viewer access for the local interview demo. An administrator user is also configured for administrative operations:
- **Username:** `admin`
- **Password:** `admin`
- **Login URL:** <http://127.0.0.1:3001/login>

Stop it with:

```powershell
.\scripts\stop-grafana.ps1
```

Database validation and AI summaries can be rerun independently:

```powershell
.\scripts\validate-database.ps1
.\scripts\validate-milestone2.ps1
.\scripts\validate-milestone2_5.ps1
.\scripts\validate-milestone4.ps1
.\scripts\validate-current-demo-state.ps1
.\scripts\test-ai-summary.ps1
```
