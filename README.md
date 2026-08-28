# ATX Maintenance Manager Demo

This project provides a PostgreSQL and Grafana interview demonstration for a fictional two-line food manufacturing maintenance operation. The design source of truth is [documentation/atx_demo_dashboard.md](documentation/atx_demo_dashboard.md).

## Prerequisites

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

The project uses the installed Grafana binary but keeps its runtime database, logs, plugins, and provisioning isolated under the ignored `.grafana` directory. PostgreSQL credentials are supplied to Grafana only through the startup process environment.

```powershell
.\scripts\start-grafana.ps1
.\scripts\validate-grafana.ps1
.\scripts\test-ai-summary.ps1
```

## Milestone 4 — Line 2 sensor-to-OEE demonstration

Milestone 4 instruments only `MIXER-201`, `CONVEYOR-201`, `FILLER-201`, and `LABELER-201` in depth. Deterministic PostgreSQL telemetry resolves into auditable states and primary Stop Reason Tags, then into Equipment OEE and Loss Analysis. Line 2 OEE is independently calculated from line time, product-specific rate, and line counts; it is never the average of machine OEE percentages.

The aligned terms are Asset Utilization / Scheduled Utilization, Equipment OEE, Line OEE, and Loss Analysis—not the legacy draft labels “OEE1” and “OEE2.” Asset Utilization is Scheduled Production Time / Total Calendar Time and is not OEE. OEE is Availability × Performance / Speed × Quality. Loss Analysis separately explains scheduled capacity, stop, unplanned-maintenance, speed, and quality losses; it is not multiplied into OEE.

Planned breaks preserve the existing convention and are outside Scheduled Production Time. Planned changeover is inside Scheduled Production Time and visible as planned production loss. Sanitation, outside-schedule planned maintenance, and no-schedule time reduce utilization but not OEE Availability. `AIR-COMP-001` remains a shared utility and is excluded from piece-rate OEE.

Apply or validate Milestone 4 on an existing database:

```powershell
.\scripts\seed-line2-equipment-inputs.ps1
.\scripts\validate-milestone4.ps1
.\scripts\validate-grafana.ps1
.\scripts\test-ai-summary.ps1
```

The guarded `rebuild-database.ps1 -ConfirmRebuild` command also applies and validates Milestone 4 after Milestone 2.5.

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
.\scripts\test-ai-summary.ps1
```
