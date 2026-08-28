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
