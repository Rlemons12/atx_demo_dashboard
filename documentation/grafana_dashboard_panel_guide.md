# Grafana Dashboard Panel Guide

This guide catalogs the actual provisioned dashboard JSON. It documents panel meaning, exact query logic, variables, and navigation so the dashboards can be used without presenter narration.

## 1. VP Operations Overview

### Dashboard purpose

How to Read This Dashboard

What needs Operations leadership's attention right now?

This is the executive scorecard. Use it to identify where performance is below target, then drill into Production & OEE, Maintenance Reliability, or Operational Risk depending on the type of loss.

### Interview question it answers

> What needs Operations leadership's attention?

### Panel 1 - How to Read This Dashboard

- **Panel title:** How to Read This Dashboard
- **Visualization type:** text
- **Purpose:** This is the executive scorecard. Use it to identify where performance is below target, then drill into Production & OEE, Maintenance Reliability, or Operational Risk depending on the type of loss. AI narrative interprets curated PostgreSQL views; it does not calculate or invent KPI values. Data source: dashboard navigation narrative.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 2 - Executive KPI Scorecard

- **Panel title:** Executive KPI Scorecard
- **Visualization type:** row
- **Purpose:** Section grouping for **Executive KPI Scorecard**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 3 - Plant Uptime — Target ≥95%

- **Panel title:** Plant Uptime — Target ≥95%
- **Visualization type:** stat
- **Purpose:** Shows the latest month in v_plant_uptime_monthly. Uptime = (two lines x 16 scheduled hours/day - immediate unplanned line-delay minutes) / scheduled minutes. Higher is better; below 95% needs attention. Plant aggregation can hide a weak line or asset, so compare the line trend, downtime-asset Pareto, and Production & OEE dashboard next. Data source: v_plant_uptime_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT uptime_percent FROM v_plant_uptime_monthly ORDER BY period DESC LIMIT 1
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_plant_uptime_monthly

### Panel 4 - PM Compliance — Target ≥98%

- **Panel title:** PM Compliance — Target ≥98%
- **Visualization type:** stat
- **Purpose:** Shows the latest monthly PM compliance. Compliance = PM executions completed on or before their scheduled date / all PM executions scheduled that month. Higher is better; the target is 98%. Missed PM increases future failure exposure, especially on critical assets. Review Overdue PMs in Maintenance Reliability next. Data source: v_pm_compliance_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT compliance_percent FROM v_pm_compliance_monthly ORDER BY period DESC LIMIT 1
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_pm_compliance_monthly

### Panel 5 - Emergency Work — Target <30%

- **Panel title:** Emergency Work — Target <30%
- **Visualization type:** stat
- **Purpose:** Shows the latest monthly reactive-work ratio: work orders flagged emergency / all work orders requested that month. Lower is better; the target is below 30%. A high value indicates maintenance resources are being pulled into breakdown response. Review PM compliance, repeat failures, and failure Pareto next. Data source: v_emergency_work_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT emergency_percent FROM v_emergency_work_monthly ORDER BY period DESC LIMIT 1
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_emergency_work_monthly

### Panel 6 - MTTR — Lower Is Better (15% Improvement Target)

- **Panel title:** MTTR — Lower Is Better (15% Improvement Target)
- **Visualization type:** stat
- **Purpose:** Shows latest-month MTTR in minutes for completed CORRECTIVE and EMERGENCY work orders with both start and completion timestamps. MTTR is average(work completed - work started). Lower is better; the target is at least 15% improvement from baseline. Review asset MTTR, work planning, skills, parts, and failure modes when it rises. Data source: v_mttr_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT mttr_minutes FROM v_mttr_monthly ORDER BY period DESC LIMIT 1
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_mttr_monthly

### Panel 7 - MTBF — Target ≥20% Improvement

- **Panel title:** MTBF — Target ≥20% Improvement
- **Visualization type:** stat
- **Purpose:** Shows latest-month plant MTBF in hours: scheduled plant hours for the month / production-stopping failure count. Higher is better; the target is at least 20% improvement from baseline. Because it is plant-level, inspect asset MTBF and repeat-failure panels to find the constraint. Data source: v_mtbf_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT mtbf_hours FROM v_mtbf_monthly ORDER BY period DESC LIMIT 1
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_mtbf_monthly

### Panel 8 - WO Closure — Target ≥95%

- **Panel title:** WO Closure — Target ≥95%
- **Visualization type:** stat
- **Purpose:** Shows the latest monthly closure rate: work orders with status CLOSED / all work orders requested that month. Higher is better; the target is 95%. Low closure can indicate execution backlog or incomplete documentation. Review open and critical work in Maintenance Reliability. Data source: v_work_order_closure_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT closure_percent FROM v_work_order_closure_monthly ORDER BY period DESC LIMIT 1
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_work_order_closure_monthly

### Panel 9 - Critical Spares — Target ≥98%

- **Panel title:** Critical Spares — Target ≥98%
- **Visualization type:** stat
- **Purpose:** Shows the latest monthly percentage of critical parts whose cumulative inventory balance is at or above minimum quantity. A part is included when it or an asset-part relationship is marked critical. Higher is better; the target is 98%. Below-target stock threatens repair duration and production recovery. Review the critical-spare inventory table next. Data source: v_critical_spares_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT availability_percent FROM v_critical_spares_monthly ORDER BY period DESC LIMIT 1
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_critical_spares_monthly

### Panel 10 - Repeat Failures — Target ≥30% Reduction

- **Panel title:** Repeat Failures — Target ≥30% Reduction
- **Visualization type:** stat
- **Purpose:** Shows the latest monthly count of failure_events explicitly flagged repeat_failure. Lower is better; the target is at least 30% reduction from baseline. Repeat flags indicate a known symptom or mode has recurred and may need RCA or corrective-action verification. Review repeat asset/mode and RCA panels next. Data source: v_repeat_failures_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT repeat_failure_count FROM v_repeat_failures_monthly ORDER BY period DESC LIMIT 1
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_repeat_failures_monthly

### Panel 11 - Production & OEE Summary

- **Panel title:** Production & OEE Summary
- **Visualization type:** row
- **Purpose:** Section grouping for **Production & OEE Summary**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 12 - Legacy Monthly Line 1 OEE — Target ≥85%

- **Panel title:** Legacy Monthly Line 1 OEE — Target ≥85%
- **Visualization type:** stat
- **Purpose:** Shows the latest monthly Line OEE from the preserved Milestone 2.5 view. That legacy view derives runtime from planned-versus-actual production and uses the historical production-calendar denominator, then calculates OEE as Availability x Performance x Quality. Higher is better. Do not compare it as if it were the newer detailed Line 2 calculation; use the independently calculated Line 2 section and Equipment OEE Detail for sensor-to-loss analysis.  **Data source:** PostgreSQL v_line_oee_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT oee_percent FROM v_line_oee_monthly WHERE line_code = 'LINE-1' ORDER BY period DESC LIMIT 1
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_line_oee_monthly

### Panel 13 - Legacy Monthly Line 2 OEE — Target ≥85%

- **Panel title:** Legacy Monthly Line 2 OEE — Target ≥85%
- **Visualization type:** stat
- **Purpose:** Shows the latest monthly Line OEE from the preserved Milestone 2.5 view. That legacy view derives runtime from planned-versus-actual production and uses the historical production-calendar denominator, then calculates OEE as Availability x Performance x Quality. Higher is better. Do not compare it as if it were the newer detailed Line 2 calculation; use the independently calculated Line 2 section and Equipment OEE Detail for sensor-to-loss analysis.  **Data source:** PostgreSQL v_line_oee_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT oee_percent FROM v_line_oee_monthly WHERE line_code = 'LINE-2' ORDER BY period DESC LIMIT 1
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_line_oee_monthly

### Panel 14 - Line 1 — Current Running Lot

- **Panel title:** Line 1 — Current Running Lot
- **Visualization type:** stat
- **Purpose:** Shows the current running production lot snapshot, product, completion progress, and yield for the named line. It is not a historical aggregation. Delayed progress or weak yield should be followed into schedule adherence, line OEE, and equipment detail.  **Data source:** PostgreSQL v_current_production_lots.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT lot_number || ' (' || product_name || ')' AS "Active Lot", progress_percent || '%' AS "Progress", yield_percent || '%' AS "Yield" FROM v_current_production_lots WHERE line_code = 'LINE-1' LIMIT 1
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_current_production_lots

### Panel 15 - Line 2 — Current Running Lot

- **Panel title:** Line 2 — Current Running Lot
- **Visualization type:** stat
- **Purpose:** Shows the current running production lot snapshot, product, completion progress, and yield for the named line. It is not a historical aggregation. Delayed progress or weak yield should be followed into schedule adherence, line OEE, and equipment detail.  **Data source:** PostgreSQL v_current_production_lots.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT lot_number || ' (' || product_name || ')' AS "Active Lot", progress_percent || '%' AS "Progress", yield_percent || '%' AS "Yield" FROM v_current_production_lots WHERE line_code = 'LINE-2' LIMIT 1
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_current_production_lots

### Panel 16 - Schedule Adherence (On-Time)

- **Panel title:** Schedule Adherence (On-Time)
- **Visualization type:** stat
- **Purpose:** Shows average on-time-start percentage for the latest available monthly period. Higher means scheduled lots began closer to plan; low values indicate execution, staffing, material, shared-asset, or changeover constraints. Review the upcoming schedule and operating-risk panels.  **Data source:** PostgreSQL v_production_schedule_adherence.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT round(avg(on_time_start_percent), 1) AS "On-Time Start %" FROM v_production_schedule_adherence WHERE period = (SELECT max(period) FROM v_production_schedule_adherence)
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_production_schedule_adherence

### Panel 17 - Shift B Staffing Snapshot — August 27, 2026

- **Panel title:** Shift B Staffing Snapshot — August 27, 2026
- **Visualization type:** stat
- **Purpose:** Shows the deterministic August 27, 2026 Shift B staffing snapshot and expected one-maintenance-technician production coverage. Treat an unexpected headcount as a coverage exception and drill to the staffing/risk dashboard.  **Data source:** PostgreSQL employee_schedules.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT count(DISTINCT employee_id) || ' On Duty (1 Maint Tech)' AS "PROD-B Staffing" FROM employee_schedules WHERE schedule_date = DATE '2026-08-27' AND shift_id = 2
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** employee_schedules

### Panel 18 - Production Performance

- **Panel title:** Production Performance
- **Visualization type:** row
- **Purpose:** Section grouping for **Production Performance**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 19 - Plant Uptime Trend (Monthly)

- **Panel title:** Plant Uptime Trend (Monthly)
- **Visualization type:** timeseries
- **Purpose:** Trends monthly plant uptime from January through August 2026 against the 95% reference. Each point uses scheduled plant minutes less immediate unplanned line-delay minutes. Rising is favorable; a decline or target miss should be explained with downtime and failure Pareto panels. Data source: v_plant_uptime_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT period AS time, uptime_percent AS "Plant Uptime (%)", 95.0 AS "Target (95%)" FROM v_plant_uptime_monthly ORDER BY period
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_plant_uptime_monthly

### Panel 20 - Line 1 vs Line 2 Uptime Trend (Line 2 Reliability Opportunity)

- **Panel title:** Line 1 vs Line 2 Uptime Trend (Line 2 Reliability Opportunity)
- **Visualization type:** timeseries
- **Purpose:** Compares monthly Line 1 and Line 2 uptime from January through August 2026. Each line uses 16 scheduled hours/day less immediate unplanned delay assigned to that line. Higher is better; the persistent Line 2 gap identifies the deeper reliability opportunity. Drill to Production & OEE and Equipment OEE Detail. Data source: v_line_uptime_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT period AS time, line_name AS metric, uptime_percent AS value FROM v_line_uptime_monthly ORDER BY period, line_name
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_line_uptime_monthly

### Panel 21 - Where Are We Losing Production?

- **Panel title:** Where Are We Losing Production?
- **Visualization type:** row
- **Purpose:** Section grouping for **Where Are We Losing Production?**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 22 - Top Downtime Assets (Pareto)

- **Panel title:** Top Downtime Assets (Pareto)
- **Visualization type:** barchart
- **Purpose:** Ranks assets by total recorded downtime minutes in descending order, so one bar represents one asset. This Pareto identifies where concentrated action can recover the most time; it does not prove every minute is maintenance-caused.  **Data source:** PostgreSQL v_downtime_by_asset.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT asset_code AS "Asset", downtime_minutes AS "Downtime (Minutes)" FROM v_downtime_by_asset ORDER BY downtime_minutes DESC LIMIT 7
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_downtime_by_asset

### Panel 23 - Top Failure Modes by Downtime

- **Panel title:** Top Failure Modes by Downtime
- **Visualization type:** barchart
- **Purpose:** Ranks failure modes by associated downtime minutes in descending order. Use it to prioritize modes with the greatest time impact, then inspect affected assets, work orders, and RCA evidence.  **Data source:** PostgreSQL v_downtime_by_failure_mode.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT failure_mode AS "Failure Mode", downtime_minutes AS "Downtime (Minutes)" FROM v_downtime_by_failure_mode ORDER BY downtime_minutes DESC LIMIT 7
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_downtime_by_failure_mode

### Panel 24 - Unplanned Downtime Reduction Trend

- **Panel title:** Unplanned Downtime Reduction Trend
- **Visualization type:** timeseries
- **Purpose:** Trends monthly immediate unplanned downtime minutes. Lower is better; a sustained decline indicates recovered production time. Use the asset and failure-mode Pareto panels to explain peaks or reversals.  **Data source:** PostgreSQL v_plant_uptime_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT period AS time, unplanned_downtime_minutes AS "Unplanned Downtime (Minutes)" FROM v_plant_uptime_monthly ORDER BY period
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_plant_uptime_monthly

### Panel 25 - Reactive vs Controlled Maintenance

- **Panel title:** Reactive vs Controlled Maintenance
- **Visualization type:** row
- **Purpose:** Section grouping for **Reactive vs Controlled Maintenance**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 26 - Planned vs Reactive Work (Monthly Work Orders)

- **Panel title:** Planned vs Reactive Work (Monthly Work Orders)
- **Visualization type:** timeseries
- **Purpose:** Trends monthly work-order counts by planned/reactive classification. A shift toward planned work indicates greater maintenance control; rising reactive work should be investigated through PM compliance and repeat failures.  **Data source:** PostgreSQL v_planned_vs_reactive_work.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT period AS time, work_classification AS metric, work_order_count AS value FROM v_planned_vs_reactive_work ORDER BY period, work_classification
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_planned_vs_reactive_work

### Panel 27 - Emergency Work Order % Trend

- **Panel title:** Emergency Work Order % Trend
- **Visualization type:** timeseries
- **Purpose:** Trends emergency work orders / total requested work orders by month against the 30% reference. Lower is better; a sustained decline indicates movement from reactive to controlled maintenance. Investigate reversals through PM compliance, repeat failures, and Maintenance Reliability. Data source: v_emergency_work_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT period AS time, emergency_percent AS "Emergency Work (%)", 30.0 AS "Target (<30%)" FROM v_emergency_work_monthly ORDER BY period
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_emergency_work_monthly

### Panel 28 - Current Operations Risks & Actions

- **Panel title:** Current Operations Risks & Actions
- **Visualization type:** row
- **Purpose:** Section grouping for **Current Operations Risks & Actions**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 29 - Current Operational & Maintenance Risks

- **Panel title:** Current Operational & Maintenance Risks
- **Visualization type:** table
- **Purpose:** Each row is one currently curated operational risk from v_operational_risks, showing risk area, affected asset, severity, condition/consequence, and mitigation status. Rows are newest first. Severe conditions with incomplete mitigation require immediate leadership assignment; drill to the dashboard matching the risk type. Data source: v_operational_risks.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT risk_type AS "Risk Area", asset_code AS "Asset", severity AS "Severity", description AS "Operational Condition & Risk", status AS "Current Mitigation / Response" FROM v_operational_risks ORDER BY identified_at DESC
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** v_operational_risks

### Panel 30 - RCA Corrective Actions Status

- **Panel title:** RCA Corrective Actions Status
- **Visualization type:** table
- **Purpose:** Each row is an RCA corrective action joined to its asset and problem statement. Status is Completed when completed_date exists, Overdue when due_date is before today, otherwise Open. The query includes open and completed actions, sorts due dates newest first, and limits to five. Overdue or unverified high-impact actions require owner follow-up in Maintenance Reliability. Data source: corrective_actions, rca_events, work_orders, assets.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT a.asset_code AS "Asset", r.problem_statement AS "Problem Statement", c.action_description AS "Corrective Action", c.due_date AS "Due Date", CASE WHEN c.completed_date IS NOT NULL THEN 'Completed' WHEN c.due_date < CURRENT_DATE THEN 'Overdue' ELSE 'Open' END AS "Status" FROM corrective_actions c JOIN rca_events r USING(rca_event_id) JOIN work_orders w USING(work_order_id) JOIN assets a USING(asset_id) ORDER BY c.due_date DESC LIMIT 5
```
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** assets, corrective_actions, rca_events, work_orders

### Panel 31 - Executive AI Maintenance Assistant

- **Panel title:** Executive AI Maintenance Assistant
- **Visualization type:** row
- **Purpose:** Section grouping for **Executive AI Maintenance Assistant**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 32 - AI Maintenance Summary

- **Panel title:** AI Maintenance Summary
- **Visualization type:** text
- **Purpose:** Executive narrative generated from curated PostgreSQL maintenance and operations views. AI may summarize, compare, and identify follow-on questions, but it does not calculate, replace, or invent KPI values. Verify every cited value in the scorecard or linked detail dashboard. Data source: curated PostgreSQL views supplied by scripts/test-ai-summary.ps1.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Drill to Production & OEE for capacity/OEE, Maintenance Reliability for failures/RCA, or Operational Risk for staffing/shared assets.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Dashboard variables

- No dashboard variables.

### Dashboard links

- **Maintenance Reliability:** /d/atx-maintenance-reliability/maintenance-reliability
- **Staffing, Sanitation & Operational Risk:** /d/atx-operational-risk/staffing-sanitation-and-operational-risk
- **Production & OEE Performance:** /d/atx-production-oee/production-and-oee-performance

## 2. Production & OEE Performance

### Dashboard purpose

How to Read This Dashboard

How are the lines performing, and where are we losing productive capacity?

Start with line utilization and OEE, identify whether Availability, Performance / Speed, or Quality is driving loss, then drill into the equipment ranking and selected-machine detail. Scheduled Utilization is not OEE, and Line OEE is not average machine OEE.

### Interview question it answers

> How are the production lines performing and where are we losing capacity?

### Panel 1 - How to Read This Dashboard

- **Panel title:** How to Read This Dashboard
- **Visualization type:** text
- **Purpose:** Start with line utilization and OEE, identify whether Availability, Performance, or Quality is driving loss, then drill into equipment ranking and selected-machine detail. Scheduled Utilization is scheduled production time / calendar time and is not OEE. Line OEE is calculated from line inputs, not average machine OEE. Data source: dashboard navigation narrative.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 2 - Current Production Status & Shift Staffing

- **Panel title:** Current Production Status & Shift Staffing
- **Visualization type:** row
- **Purpose:** Section grouping for **Current Production Status & Shift Staffing**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 3 - Line 1 — Active Lot Status (Running)

- **Panel title:** Line 1 — Active Lot Status (Running)
- **Visualization type:** stat
- **Purpose:** Shows the current Line 1 RUNNING lot from v_current_production_lots: lot, product, progress, and yield. One displayed value set represents the current deterministic snapshot, not a historical period. Low progress versus elapsed schedule or weak yield should be checked against schedule adherence and line OEE; Shift B context is shown in the staffing roster. Data source: v_current_production_lots.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT lot_number AS "Active Lot", product_name AS "Product", progress_percent || '%' AS "Progress", yield_percent || '%' AS "Yield" FROM v_current_production_lots WHERE line_code = 'LINE-1'
```
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** v_current_production_lots

### Panel 4 - Line 2 — Active Lot Status (Running)

- **Panel title:** Line 2 — Active Lot Status (Running)
- **Visualization type:** stat
- **Purpose:** Shows the current Line 2 RUNNING lot from v_current_production_lots: lot, product, progress, and yield. One displayed value set represents the current deterministic snapshot, not a historical period. Low progress or yield should be followed into detailed Line 2 OEE, equipment contributors, and Filler-201 detail; Shift B context is in the roster. Data source: v_current_production_lots.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT lot_number AS "Active Lot", product_name AS "Product", progress_percent || '%' AS "Progress", yield_percent || '%' AS "Yield" FROM v_current_production_lots WHERE line_code = 'LINE-2'
```
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** v_current_production_lots

### Panel 5 - Current Staffing Roster (Shift B — 1/1/0 Model)

- **Panel title:** Current Staffing Roster (Shift B — 1/1/0 Model)
- **Visualization type:** table
- **Purpose:** Each row is one employee in the deterministic current Shift B schedule, ordered by role. Columns show assigned role, employee, line/plant assignment, and confirmation status. Expected production coverage is one lead, one operator per line, and one maintenance technician; missing or unconfirmed roles require Operational Risk review. Data source: v_employee_schedule_current.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT assigned_role AS "Role", employee_name AS "Employee", line_assignment AS "Line", status AS "Status" FROM v_employee_schedule_current ORDER BY assigned_role
```
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** v_employee_schedule_current

### Panel 6 - Schedule Adherence (Current Month)

- **Panel title:** Schedule Adherence (Current Month)
- **Visualization type:** stat
- **Purpose:** Shows average on-time-start percentage for the latest available monthly period. Higher means scheduled lots began closer to plan; low values indicate execution, staffing, material, shared-asset, or changeover constraints. Review the upcoming schedule and operating-risk panels.  **Data source:** PostgreSQL v_production_schedule_adherence.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT round(avg(on_time_start_percent), 1) AS "On-Time Start %" FROM v_production_schedule_adherence WHERE period = (SELECT max(period) FROM v_production_schedule_adherence)
```
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** v_production_schedule_adherence

### Panel 7 - Line OEE Scorecard & Components

- **Panel title:** Line OEE Scorecard & Components
- **Visualization type:** row
- **Purpose:** Section grouping for **Line OEE Scorecard & Components**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 8 - Legacy Monthly Line 1 OEE — Target ≥85%

- **Panel title:** Legacy Monthly Line 1 OEE — Target ≥85%
- **Visualization type:** stat
- **Purpose:** Shows the latest monthly Line OEE from the preserved Milestone 2.5 view. That legacy view derives runtime from planned-versus-actual production and uses the historical production-calendar denominator, then calculates OEE as Availability x Performance x Quality. Higher is better. Do not compare it as if it were the newer detailed Line 2 calculation; use the independently calculated Line 2 section and Equipment OEE Detail for sensor-to-loss analysis.  **Data source:** PostgreSQL v_line_oee_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT oee_percent FROM v_line_oee_monthly WHERE line_code = 'LINE-1' ORDER BY period DESC LIMIT 1
```
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** v_line_oee_monthly

### Panel 9 - Line 1 A / P / Q Components

- **Panel title:** Line 1 A / P / Q Components
- **Visualization type:** stat
- **Purpose:** Shows Availability, Performance, and Quality for the latest month under the preserved Milestone 2.5 line convention. Availability uses the legacy inferred runtime and historical planned-production denominator; Performance compares output with ideal-rate output during that runtime; Quality is good/total output. Use the lowest component diagnostically, then use the detailed Line 2 section for the Milestone 4 time-accounting convention.  **Data source:** PostgreSQL v_line_oee_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT availability_percent AS "Availability (%)", performance_percent AS "Performance (%)", quality_percent AS "Quality (%)" FROM v_line_oee_monthly WHERE line_code = 'LINE-1' ORDER BY period DESC LIMIT 1
```
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** v_line_oee_monthly

### Panel 10 - Legacy Monthly Line 2 OEE — Target ≥85%

- **Panel title:** Legacy Monthly Line 2 OEE — Target ≥85%
- **Visualization type:** stat
- **Purpose:** Shows the latest monthly Line OEE from the preserved Milestone 2.5 view. That legacy view derives runtime from planned-versus-actual production and uses the historical production-calendar denominator, then calculates OEE as Availability x Performance x Quality. Higher is better. Do not compare it as if it were the newer detailed Line 2 calculation; use the independently calculated Line 2 section and Equipment OEE Detail for sensor-to-loss analysis.  **Data source:** PostgreSQL v_line_oee_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT oee_percent FROM v_line_oee_monthly WHERE line_code = 'LINE-2' ORDER BY period DESC LIMIT 1
```
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** v_line_oee_monthly

### Panel 11 - Line 2 A / P / Q Components

- **Panel title:** Line 2 A / P / Q Components
- **Visualization type:** stat
- **Purpose:** Shows Availability, Performance, and Quality for the latest month under the preserved Milestone 2.5 line convention. Availability uses the legacy inferred runtime and historical planned-production denominator; Performance compares output with ideal-rate output during that runtime; Quality is good/total output. Use the lowest component diagnostically, then use the detailed Line 2 section for the Milestone 4 time-accounting convention.  **Data source:** PostgreSQL v_line_oee_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT availability_percent AS "Availability (%)", performance_percent AS "Performance (%)", quality_percent AS "Quality (%)" FROM v_line_oee_monthly WHERE line_code = 'LINE-2' ORDER BY period DESC LIMIT 1
```
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** v_line_oee_monthly

### Panel 12 - Historical Monthly Line OEE Trend — Legacy Convention

- **Panel title:** Historical Monthly Line OEE Trend — Legacy Convention
- **Visualization type:** timeseries
- **Purpose:** Shows the latest monthly Line OEE from the preserved Milestone 2.5 view. That legacy view derives runtime from planned-versus-actual production and uses the historical production-calendar denominator, then calculates OEE as Availability x Performance x Quality. Higher is better. Do not compare it as if it were the newer detailed Line 2 calculation; use the independently calculated Line 2 section and Equipment OEE Detail for sensor-to-loss analysis. **Data source:** PostgreSQL v_line_oee_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT period AS time, line_name AS metric, oee_percent AS value FROM v_line_oee_monthly WHERE ('$line' = '%' OR line_code = '$line') ORDER BY period, line_name
```
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** v_line_oee_monthly

### Panel 13 - Equipment OEE Ranking & Loss Breakdown

- **Panel title:** Equipment OEE Ranking & Loss Breakdown
- **Visualization type:** row
- **Purpose:** Section grouping for **Equipment OEE Ranking & Loss Breakdown**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 14 - Equipment OEE Ranking (Worst-to-Best — Excludes Utility Air-Comp)

- **Panel title:** Equipment OEE Ranking (Worst-to-Best — Excludes Utility Air-Comp)
- **Visualization type:** table
- **Purpose:** Each row is one completed production asset from the legacy Equipment OEE summary, excluding shared utilities such as Air-Comp-001 and filtered by line/asset variables. Rows sort lowest OEE first and show Availability, Performance, Quality, and Equipment OEE. Low rows identify diagnostic contributors only: Line OEE is not calculated by averaging Equipment OEE. Drill to Equipment OEE Detail for the four instrumented Line 2 machines. Data source: v_asset_oee_components.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT asset_code AS "Asset", asset_name AS "Asset Name", equipment_type AS "Type", line_code AS "Line", overall_availability_percent AS "Availability (%)", overall_performance_percent AS "Performance (%)", overall_quality_percent AS "Quality (%)", overall_oee_percent AS "OEE (%)" FROM v_asset_oee_components WHERE ('$line' = '%' OR line_code = '$line') AND ('$asset' = '%' OR asset_code = '$asset') ORDER BY overall_oee_percent ASC
```
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** v_asset_oee_components

### Panel 15 - Production Time Loss Categories — August 2026

- **Panel title:** Production Time Loss Categories — August 2026
- **Visualization type:** barchart
- **Purpose:** Ranks August 2026 production-time loss minutes by category for the selected line(s), largest first. Categories combine recorded downtime, planned changeover, and planned breaks under the legacy view convention; they explain lost time and are not multiplied into OEE again. Distinguish planned loss from maintenance, production, material, and quality causes before assigning action. Data source: v_oee_loss_by_category.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT loss_category AS "Loss Category", sum(loss_minutes) AS "Loss (Minutes)" FROM v_oee_loss_by_category WHERE period = '2026-08-01' AND ('$line' = '%' OR line_code = '$line') GROUP BY loss_category ORDER BY 2 DESC
```
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** v_oee_loss_by_category

### Panel 16 - Filler-201 Case Study: RCA Impact on OEE

- **Panel title:** Filler-201 Case Study: RCA Impact on OEE
- **Visualization type:** row
- **Purpose:** Section grouping for **Filler-201 Case Study: RCA Impact on OEE**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 17 - Filler-201 Pre vs Post RCA OEE Transformation (Bracket Root Cause Fix)

- **Panel title:** Filler-201 Pre vs Post RCA OEE Transformation (Bracket Root Cause Fix)
- **Visualization type:** table
- **Purpose:** Each row compares Filler-201 PRE_RCA (Jan-May 2026) with POST_RCA (Jun-Aug 2026), showing Availability, Performance, Quality, OEE, downtime, failures, and repeat failures. The post period follows bracket replacement, locking hardware, and weekly PM revision. Higher Availability/OEE with lower downtime and recurrence supports corrective-action effectiveness. Drill to Equipment Detail or Maintenance Reliability for stop and RCA evidence. Data source: v_filler201_oee_before_after_rca.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT rca_period AS "Period", availability_percent AS "Availability (%)", performance_percent AS "Performance (%)", quality_percent AS "Quality (%)", oee_percent AS "OEE (%)", total_downtime_minutes AS "Downtime (Min)", total_failures AS "Failures", repeat_failures AS "Repeat Failures" FROM v_filler201_oee_before_after_rca ORDER BY rca_period DESC
```
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** v_filler201_oee_before_after_rca

### Panel 18 - Filler-201 Monthly OEE & Availability Recovery Trend

- **Panel title:** Filler-201 Monthly OEE & Availability Recovery Trend
- **Visualization type:** timeseries
- **Purpose:** Trends monthly Filler-201 OEE and Availability across the seeded January-August 2026 history. OEE is Availability x Performance x Quality under the legacy monthly equipment convention. The June 2026 RCA/PM revision is the intervention point; sustained improvement afterward supports effectiveness. Drill to Filler-201 Equipment Detail for Stop Loss and sensor evidence. Data source: v_asset_oee_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT period AS time, oee_percent AS "Filler-201 OEE (%)", availability_percent AS "Availability (%)" FROM v_asset_oee_monthly WHERE asset_code = 'FILLER-201' ORDER BY period
```
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** v_asset_oee_monthly

### Panel 19 - Production Scheduling & Performance Standards

- **Panel title:** Production Scheduling & Performance Standards
- **Visualization type:** row
- **Purpose:** Section grouping for **Production Scheduling & Performance Standards**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 20 - Upcoming Production Lots Schedule

- **Panel title:** Upcoming Production Lots Schedule
- **Visualization type:** table
- **Purpose:** Each row is one upcoming READY or PLANNED production lot, ordered by scheduled start then line and limited to ten. Columns show sequence, line, lot, product, scheduled window, planned quantity, and status; running/completed/cancelled lots are excluded. Conflicts, delays, or large shared-resource demand should be checked against Blender scheduling and staffing. Data source: production_schedule, production_lots, production_lines, products.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT ps.sequence_number AS "Seq", l.line_code AS "Line", pl.lot_number AS "Lot Number", p.product_name AS "Product", ps.scheduled_start AS "Scheduled Start", ps.scheduled_end AS "Scheduled End", pl.planned_quantity AS "Planned Qty", pl.status AS "Status" FROM production_schedule ps JOIN production_lots pl USING(lot_id) JOIN production_lines l ON l.line_id=ps.line_id JOIN products p ON p.product_id=pl.product_id WHERE pl.status IN ('READY', 'PLANNED') ORDER BY ps.scheduled_start, l.line_code LIMIT 10
```
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** production_lines, production_lots, production_schedule, products

### Panel 21 - Product-Line Speed & Changeover Standards (OEE Benchmark)

- **Panel title:** Product-Line Speed & Changeover Standards (OEE Benchmark)
- **Visualization type:** table
- **Purpose:** Each row is one product/line standard filtered by line and product: ideal units/minute, expected yield, and standard changeover minutes. Ideal rate sets the theoretical Performance denominator; expected yield supports quality planning; changeover standard supports planned-loss review. Stale or unrealistic standards distort interpretation and require Production/Engineering review. Data source: product_line_standards, products, production_lines.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT p.product_code AS "SKU", p.product_name AS "Product Name", l.line_code AS "Line", pls.ideal_units_per_minute AS "Ideal Rate (Units/Min)", pls.expected_yield_pct AS "Expected Yield (%)", pls.standard_changeover_minutes AS "Std Changeover (Min)" FROM product_line_standards pls JOIN products p USING(product_id) JOIN production_lines l USING(line_id) WHERE ('$line' = '%' OR l.line_code = '$line') AND ('$product' = '%' OR p.product_code = '$product') ORDER BY l.line_code, p.product_code
```
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** product_line_standards, production_lines, products

### Panel 22 - Shared Assets & Plant Utilities Risk

- **Panel title:** Shared Assets & Plant Utilities Risk
- **Visualization type:** row
- **Purpose:** Section grouping for **Shared Assets & Plant Utilities Risk**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 23 - Blender-001 Shared Production Schedule & Conflict Risk

- **Panel title:** Blender-001 Shared Production Schedule & Conflict Risk
- **Visualization type:** table
- **Purpose:** Each row is a scheduled Blender-001 slot with line, start/end, order, current/future risk status, and current equipment status, ordered chronologically. Blender-001 is allocated sequentially, so a current failure can delay the active line and the next reserved line. Coordinate Production and Maintenance when risk_timing indicates future exposure. Data source: v_shared_asset_risk.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT line_code AS "Line", scheduled_start AS "Start", scheduled_end AS "End", production_order AS "Production Order", risk_timing AS "Risk Status", CASE WHEN asset_currently_down THEN 'DOWN' ELSE 'OPERATIONAL' END AS "Equipment Status" FROM v_shared_asset_risk WHERE asset_code = 'BLENDER-001' ORDER BY scheduled_start
```
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** v_shared_asset_risk

### Panel 24 - Air-Comp-001 Utility Vibration Trend (Shared Plant Risk — No OEE)

- **Panel title:** Air-Comp-001 Utility Vibration Trend (Shared Plant Risk — No OEE)
- **Visualization type:** timeseries
- **Purpose:** Trends all seeded Air-Comp-001 vibration observations with 2.8 mm/s warning and 4.5 mm/s alarm references. Rising or threshold-crossing vibration indicates condition degradation. The compressor simultaneously supports both lines, so predictive intervention is plant-critical; as a shared utility it does not receive piece-rate OEE. Drill to Operational Risk condition panels. Data source: v_condition_measurements.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT time, numeric_value AS "Vibration (mm/s)", warning_threshold AS "Warning (2.8 mm/s)", alarm_threshold AS "Alarm (4.5 mm/s)" FROM v_condition_measurements WHERE asset_code = 'AIR-COMP-001' AND measurement_type = 'VIBRATION' ORDER BY time
```
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** v_condition_measurements

### Panel 25 - Executive AI Production & OEE Assistant

- **Panel title:** Executive AI Production & OEE Assistant
- **Visualization type:** row
- **Purpose:** Section grouping for **Executive AI Production & OEE Assistant**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 26 - AI Production & OEE Decision Support

- **Panel title:** AI Production & OEE Decision Support
- **Visualization type:** text
- **Purpose:** AI production narrative interprets curated PostgreSQL lot, schedule, OEE, loss, staffing, and risk views. It may explain relationships but does not calculate, overwrite, or invent KPI values. Validate cited numbers in the live panels and use Equipment OEE Detail for machine evidence. Data source: curated views supplied by scripts/test-ai-summary.ps1.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 27 - Line 2 OEE → Equipment OEE Contributors → Raw Inputs & Loss Analysis

- **Panel title:** Line 2 OEE → Equipment OEE Contributors → Raw Inputs & Loss Analysis
- **Visualization type:** row
- **Purpose:** Section grouping for **Line 2 OEE → Equipment OEE Contributors → Raw Inputs & Loss Analysis**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 28 - LINE 2 OEE (independent line calculation, not machine average)

- **Panel title:** LINE 2 OEE (independent line calculation, not machine average)
- **Visualization type:** stat
- **Purpose:** Shows detailed Line 2 Scheduled Utilization, Availability, Performance, Quality, and OEE from independent line-level inputs. Utilization = scheduled production/calendar time and is not OEE. OEE = runtime/scheduled time x actual/theoretical output x good/total output; it is not average machine OEE. Low components direct the next investigation to time, speed, or quality. Data source: v_line2_oee_summary.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT oee_percent AS "LINE 2 OEE",utilization_percent AS "Line 2 Utilization",availability_percent AS "Line 2 Availability",performance_percent AS "Line 2 Performance",quality_percent AS "Line 2 Quality" FROM v_line2_oee_summary
```
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** v_line2_oee_summary

### Panel 29 - Line 2 Equipment OEE Contributors — click Asset to drill into inputs and losses

- **Panel title:** Line 2 Equipment OEE Contributors — click Asset to drill into inputs and losses
- **Visualization type:** table
- **Purpose:** Each row is one of the four instrumented Line 2 machines, in process order, with Scheduled Utilization, Availability, Performance, Quality, Equipment OEE, and unscheduled Stop Loss minutes. Values diagnose contributors; they are not averaged into Line OEE. Click Asset to inspect time accounting, Stop Reasons, sensors, and RCA trace. Data source: v_equipment_oee_summary.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT asset_code AS "Asset",utilization_percent AS "Scheduled Utilization %",availability_percent AS "Availability %",performance_percent AS "Performance %",quality_percent AS "Quality %",oee_percent AS "Equipment OEE %",stop_loss_minutes AS "Stop Loss Minutes" FROM v_equipment_oee_summary ORDER BY CASE asset_code WHEN 'MIXER-201' THEN 1 WHEN 'CONVEYOR-201' THEN 2 WHEN 'FILLER-201' THEN 3 WHEN 'LABELER-201' THEN 4 END
```
- **Drill-down:** Drill from Line 2 and its equipment table to Equipment OEE Detail, then use Maintenance Reliability for RCA.
- **PostgreSQL source view/table:** v_equipment_oee_summary

### Dashboard variables

- **$line - Production Line:** `SELECT 'All' AS __text, '%' AS __value UNION ALL SELECT DISTINCT name, line_code FROM production_lines ORDER BY 1`
- **$product - Product:** `SELECT 'All' AS __text, '%' AS __value UNION ALL SELECT DISTINCT product_name, product_code FROM products ORDER BY 1`
- **$asset - Asset:** `SELECT 'All' AS __text, '%' AS __value UNION ALL SELECT DISTINCT name, asset_code FROM assets WHERE scope <> 'SHARED_UTILITY' ORDER BY 1`

### Dashboard links

- **VP Operations Overview:** /d/atx-vp-operations/vp-operations-overview
- **Maintenance Reliability:** /d/atx-maintenance-reliability/maintenance-reliability
- **Staffing, Sanitation & Operational Risk:** /d/atx-operational-risk/staffing-sanitation-and-operational-risk
- **Equipment OEE Detail:** /d/atx-equipment-oee-detail/equipment-oee-detail?var-asset=FILLER-201

## 3. Equipment OEE Detail

### Dashboard purpose

How to Read This Dashboard

Why is this specific machine performing the way it is?

Follow the selected Line 2 asset through Calendar Capacity / Scheduled Utilization -> OEE = Availability x Performance x Quality -> Time Accounting -> Stop Reason and Loss Analysis -> Sensor Evidence -> Work Order / RCA / Corrective Action / PM Revision.

Scheduled Utilization measures scheduled calendar capacity and is not OEE. Continue downward to distinguish planned changeover, unscheduled Stop Loss, speed loss, quality loss, and maintenance-attributable loss.

### Interview question it answers

> Why is this specific machine performing the way it is?

### Panel 1 - 1. Selected Line 2 Equipment — What is running and what are we measuring?

- **Panel title:** 1. Selected Line 2 Equipment — What is running and what are we measuring?
- **Visualization type:** row
- **Purpose:** Section grouping for **1. Selected Line 2 Equipment — What is running and what are we measuring?**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Continue downward from scorecard to time, Stop Loss, sensors, and maintenance/RCA trace; return to Production & OEE for line context.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 2 - How to Read This Dashboard

- **Panel title:** How to Read This Dashboard
- **Visualization type:** text
- **Purpose:** Dashboard guidance and decision-support narrative. It explains the management question, intended reading order, and next drill-down; it does not calculate a KPI. Data source: dashboard narrative.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Continue downward from scorecard to time, Stop Loss, sensors, and maintenance/RCA trace; return to Production & OEE for line context.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 3 - Selected equipment identity, production context, and latest state

- **Panel title:** Selected equipment identity, production context, and latest state
- **Visualization type:** table
- **Purpose:** The single row identifies the selected asset and its latest deterministic lot, product, shift, operator, machine state, fault, and sensor timestamp. It is a current/latest snapshot; stale timestamps or faulted/stopped states direct attention to sensor and stop panels.  **Data source:** PostgreSQL v_line2_equipment_current.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT asset_code AS "Asset",equipment_type AS "Equipment Type",line_code AS "Line",lot_number AS "Current Lot",product_name AS "Product",shift_code AS "Shift",operator_name AS "Operator",state_code AS "Current Machine State",COALESCE(current_fault,'None') AS "Current Fault",last_sensor_update AS "Last Sensor Update" FROM v_line2_equipment_current WHERE asset_code='$asset'
```
- **Drill-down:** Continue downward from scorecard to time, Stop Loss, sensors, and maintenance/RCA trace; return to Production & OEE for line context.
- **PostgreSQL source view/table:** v_line2_equipment_current

### Panel 4 - 2. Equipment Scorecard — OEE = Availability × Performance × Quality

- **Panel title:** 2. Equipment Scorecard — OEE = Availability × Performance × Quality
- **Visualization type:** row
- **Purpose:** Section grouping for **2. Equipment Scorecard — OEE = Availability × Performance × Quality**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Continue downward from scorecard to time, Stop Loss, sensors, and maintenance/RCA trace; return to Production & OEE for line context.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 5 - Equipment OEE

- **Panel title:** Equipment OEE
- **Visualization type:** stat
- **Purpose:** Shows Equipment OEE for the selected asset: Availability × Performance × Quality during scheduled production. Higher is better, but the component cards and loss panels identify the actionable cause.  **Data source:** PostgreSQL v_equipment_oee_summary.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT oee_percent AS "Equipment OEE" FROM v_equipment_oee_summary WHERE asset_code='$asset'
```
- **Drill-down:** Continue downward from scorecard to time, Stop Loss, sensors, and maintenance/RCA trace; return to Production & OEE for line context.
- **PostgreSQL source view/table:** v_equipment_oee_summary

### Panel 6 - Scheduled Utilization

- **Panel title:** Scheduled Utilization
- **Visualization type:** stat
- **Purpose:** Shows Scheduled Production Time ÷ Total Calendar Time for the selected asset. This is not OEE: low utilization may reflect no schedule, sanitation, planned maintenance, or shutdowns rather than poor equipment performance.  **Data source:** PostgreSQL v_equipment_oee_summary.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT utilization_percent AS "Scheduled Utilization" FROM v_equipment_oee_summary WHERE asset_code='$asset'
```
- **Drill-down:** Continue downward from scorecard to time, Stop Loss, sensors, and maintenance/RCA trace; return to Production & OEE for line context.
- **PostgreSQL source view/table:** v_equipment_oee_summary

### Panel 7 - Availability

- **Panel title:** Availability
- **Visualization type:** stat
- **Purpose:** Shows Runtime ÷ Scheduled Production Time. Low Availability means scheduled time was consumed while the asset was not running; inspect planned changeover and unscheduled Stop Loss separately.  **Data source:** PostgreSQL v_equipment_oee_summary.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT availability_percent AS "Availability" FROM v_equipment_oee_summary WHERE asset_code='$asset'
```
- **Drill-down:** Continue downward from scorecard to time, Stop Loss, sensors, and maintenance/RCA trace; return to Production & OEE for line context.
- **PostgreSQL source view/table:** v_equipment_oee_summary

### Panel 8 - Performance / Speed

- **Panel title:** Performance / Speed
- **Visualization type:** stat
- **Purpose:** Shows Actual Output ÷ Theoretical Output at the ideal rate during Runtime. Low Performance isolates running-below-standard speed loss; inspect rate and cycle-time sensor trends.  **Data source:** PostgreSQL v_equipment_oee_summary.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT performance_percent AS "Performance / Speed" FROM v_equipment_oee_summary WHERE asset_code='$asset'
```
- **Drill-down:** Continue downward from scorecard to time, Stop Loss, sensors, and maintenance/RCA trace; return to Production & OEE for line context.
- **PostgreSQL source view/table:** v_equipment_oee_summary

### Panel 9 - Quality

- **Panel title:** Quality
- **Visualization type:** stat
- **Purpose:** Shows Good Output ÷ Total Output. Low Quality means a larger rejected share; inspect reject counts and quality-hold context.  **Data source:** PostgreSQL v_equipment_oee_summary.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT quality_percent AS "Quality" FROM v_equipment_oee_summary WHERE asset_code='$asset'
```
- **Drill-down:** Continue downward from scorecard to time, Stop Loss, sensors, and maintenance/RCA trace; return to Production & OEE for line context.
- **PostgreSQL source view/table:** v_equipment_oee_summary

### Panel 10 - 3. Time Accounting — Where calendar and scheduled minutes went

- **Panel title:** 3. Time Accounting — Where calendar and scheduled minutes went
- **Visualization type:** row
- **Purpose:** Section grouping for **3. Time Accounting — Where calendar and scheduled minutes went**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Continue downward from scorecard to time, Stop Loss, sensors, and maintenance/RCA trace; return to Production & OEE for line context.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 11 - Calendar → Scheduled Production → Runtime (minutes)

- **Panel title:** Calendar → Scheduled Production → Runtime (minutes)
- **Visualization type:** barchart
- **Purpose:** Shows time disposition for the selected asset: calendar time, scheduled downtime, scheduled production, planned changeover, unscheduled downtime, and runtime. Changeover is inside the scheduled window; sanitation/no-schedule time is outside it. Follow unexpected gaps into loss accounting.  **Data source:** PostgreSQL v_equipment_time_accounting.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT calendar_minutes AS "Total Calendar Time",scheduled_downtime_minutes AS "Scheduled Downtime",scheduled_production_minutes AS "Scheduled Production Time",changeover_minutes AS "Planned Changeover (inside schedule)",unscheduled_downtime_minutes AS "Unscheduled Downtime",runtime_minutes AS "Actual Runtime" FROM v_equipment_time_accounting WHERE asset_code='$asset'
```
- **Drill-down:** Continue downward from scorecard to time, Stop Loss, sensors, and maintenance/RCA trace; return to Production & OEE for line context.
- **PostgreSQL source view/table:** v_equipment_time_accounting

### Panel 12 - 4. Loss Accounting — Which kind of loss is reducing the result?

- **Panel title:** 4. Loss Accounting — Which kind of loss is reducing the result?
- **Visualization type:** row
- **Purpose:** Section grouping for **4. Loss Accounting — Which kind of loss is reducing the result?**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Continue downward from scorecard to time, Stop Loss, sensors, and maintenance/RCA trace; return to Production & OEE for line context.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 13 - Separate stop, speed, quality, and maintenance-attributable losses

- **Panel title:** Separate stop, speed, quality, and maintenance-attributable losses
- **Visualization type:** stat
- **Purpose:** Shows separate loss measures for the selected asset. Stop Loss is unscheduled stopped time with one primary reason; opportunity converts it using ideal rate. Performance and Quality losses remain separate, and maintenance-attributable minutes exclude operations, material, quality, safety, and scheduling causes.  **Data source:** PostgreSQL v_equipment_oee_summary.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT stop_loss_minutes AS "Stop Loss Minutes",stop_loss_opportunity_units AS "Stop Opportunity",performance_loss_percent AS "Performance Loss %",performance_loss_units AS "Performance Loss Units",performance_loss_equivalent_minutes AS "Equivalent Speed-Loss Minutes",quality_loss_percent AS "Quality Loss %",quality_loss_units AS "Quality Loss Units",unplanned_maintenance_loss_minutes AS "Maintenance-attributable Minutes" FROM v_equipment_oee_summary WHERE asset_code='$asset'
```
- **Drill-down:** Continue downward from scorecard to time, Stop Loss, sensors, and maintenance/RCA trace; return to Production & OEE for line context.
- **PostgreSQL source view/table:** v_equipment_oee_summary

### Panel 14 - 5. Stop Loss Pareto — Why was the machine stopped?

- **Panel title:** 5. Stop Loss Pareto — Why was the machine stopped?
- **Visualization type:** row
- **Purpose:** Section grouping for **5. Stop Loss Pareto — Why was the machine stopped?**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Continue downward from scorecard to time, Stop Loss, sensors, and maintenance/RCA trace; return to Production & OEE for line context.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 15 - Primary Stop Reason Pareto — a stopped machine is not automatically a maintenance problem

- **Panel title:** Primary Stop Reason Pareto — a stopped machine is not automatically a maintenance problem
- **Visualization type:** table
- **Purpose:** Each row aggregates one primary Stop Reason Tag for the selected asset, sorted by total minutes. It shows category, responsible function, maintenance flag, automatic/manual provenance, count, duration, opportunity, and scheduled-time share. WAITING_UPSTREAM means unavailable infeed; WAITING_DOWNSTREAM means unavailable takeaway. E-stops and jams are not automatically maintenance. UNCLASSIFIED_STOP means evidence was insufficient. A stopped machine is not automatically a maintenance problem.  **Data source:** PostgreSQL v_equipment_loss_summary, v_equipment_oee_summary.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT stop_reason AS "Stop Reason Tag",loss_category AS "Loss Category",responsible_function AS "Responsible Function (routing, not blame)",maintenance_related AS "Maintenance Related",classification_method AS "Classification",stop_count AS "Stop Count",stop_loss_minutes AS "Total Minutes",average_duration_minutes AS "Average Duration",stop_loss_opportunity_units AS "Lost Production Opportunity",round(100*stop_loss_minutes/(SELECT scheduled_production_minutes FROM v_equipment_oee_summary WHERE asset_code='$asset'),2) AS "% Scheduled Production" FROM v_equipment_loss_summary WHERE asset_code='$asset' ORDER BY stop_loss_minutes DESC
```
- **Drill-down:** Continue downward from scorecard to time, Stop Loss, sensors, and maintenance/RCA trace; return to Production & OEE for line context.
- **PostgreSQL source view/table:** v_equipment_loss_summary, v_equipment_oee_summary

### Panel 16 - 6. Sensor and Input Trends — What evidence supports the equipment result?

- **Panel title:** 6. Sensor and Input Trends — What evidence supports the equipment result?
- **Visualization type:** row
- **Purpose:** Section grouping for **6. Sensor and Input Trends — What evidence supports the equipment result?**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Continue downward from scorecard to time, Stop Loss, sensors, and maintenance/RCA trace; return to Production & OEE for line context.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 17 - Run/fault, counts, rate/cycle, and asset-specific condition inputs

- **Panel title:** Run/fault, counts, rate/cycle, and asset-specific condition inputs
- **Visualization type:** timeseries
- **Purpose:** Trends selected-asset synthetic inputs over the dashboard time range. Discrete run/fault/photoeye states are mapped to 0/1 while counts, rate, cycle, and condition signals retain numeric values. Correlate state changes and flat counters with Stop Reason Tags before assigning cause.  **Data source:** PostgreSQL v_line2_sensor_history.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT time,COALESCE(numeric_value,CASE discrete_value WHEN 'RUNNING' THEN 1 WHEN 'ACTIVE' THEN 1 WHEN 'FAULTED' THEN 1 WHEN 'INTERMITTENT' THEN 1 WHEN 'PRESENT' THEN 1 WHEN 'PRODUCT_DETECTED' THEN 1 ELSE 0 END) AS value,functional_class AS metric FROM v_line2_sensor_history WHERE asset_code='$asset' AND $__timeFilter(time) ORDER BY time
```
- **Drill-down:** Continue downward from scorecard to time, Stop Loss, sensors, and maintenance/RCA trace; return to Production & OEE for line context.
- **PostgreSQL source view/table:** v_line2_sensor_history

### Panel 18 - 7. Maintenance and RCA Trace — What action changed the result?

- **Panel title:** 7. Maintenance and RCA Trace — What action changed the result?
- **Visualization type:** row
- **Purpose:** Section grouping for **7. Maintenance and RCA Trace — What action changed the result?**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Continue downward from scorecard to time, Stop Loss, sensors, and maintenance/RCA trace; return to Production & OEE for line context.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 19 - Sensor/Stop → Downtime → Work Order → Failure Mode → RCA → Corrective Action → PM Revision

- **Panel title:** Sensor/Stop → Downtime → Work Order → Failure Mode → RCA → Corrective Action → PM Revision
- **Visualization type:** table
- **Purpose:** Each row is one task in a Filler-201 weekly PM revision, ordered by revision and task sequence. Compare revisions to confirm RCA learning changed preventive work content.  **Data source:** PostgreSQL v_equipment_maintenance_trace.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT downtime_start AS "Downtime",downtime_reason AS "Downtime Event",work_order_number AS "Work Order",failure_mode AS "Failure Mode",rca_number AS "RCA",root_cause AS "Root Cause",action_description AS "Corrective Action",pm_code AS "PM Plan",pm_revision AS "PM Revision",change_reason AS "PM Change" FROM v_equipment_maintenance_trace WHERE asset_code='$asset' ORDER BY downtime_start DESC
```
- **Drill-down:** Continue downward from scorecard to time, Stop Loss, sensors, and maintenance/RCA trace; return to Production & OEE for line context.
- **PostgreSQL source view/table:** v_equipment_maintenance_trace

### Panel 20 - Filler-201 Before vs After RCA — did the corrective action work?

- **Panel title:** Filler-201 Before vs After RCA — did the corrective action work?
- **Visualization type:** table
- **Purpose:** For Filler-201 only, each row summarizes PRE_RCA or POST_RCA unscheduled stops, total minutes, photoeye minutes, and average duration. Lower post-RCA values support effectiveness of the bracket/locking correction and PM revision.  **Data source:** PostgreSQL v_filler201_stop_loss_before_after_rca.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT rca_period AS "Filler-201 RCA Period",stop_count AS "Stops",stop_loss_minutes AS "Stop Loss Minutes",photoeye_stop_minutes AS "Photoeye Stop Minutes",average_stop_minutes AS "Average Stop Minutes" FROM v_filler201_stop_loss_before_after_rca WHERE '$asset'='FILLER-201' ORDER BY rca_period
```
- **Drill-down:** Continue downward from scorecard to time, Stop Loss, sensors, and maintenance/RCA trace; return to Production & OEE for line context.
- **PostgreSQL source view/table:** v_filler201_stop_loss_before_after_rca

### Dashboard variables

- **$asset - Line 2 Equipment:** `SELECT name AS __text,asset_code AS __value FROM assets WHERE asset_code IN ('MIXER-201','CONVEYOR-201','FILLER-201','LABELER-201') ORDER BY CASE asset_code WHEN 'FILLER-201' THEN 0 ELSE 1 END,asset_code`

### Dashboard links

- **Production & OEE Performance:** /d/atx-production-oee/production-and-oee-performance
- **VP Operations Overview:** /d/atx-vp-operations/vp-operations-overview
- **All Dashboards:**

## 4. Maintenance Reliability

### Dashboard purpose

How to Read This Dashboard

Which maintenance problems are driving production loss, and are corrective actions working?

Use this dashboard to move from symptom to root cause. Start with downtime and failure Pareto, inspect the affected asset and work orders, then verify RCA, corrective action, PM revision, and post-action performance.

### Interview question it answers

> Which maintenance problems are reducing reliability and are our actions improving the results?

### Panel 1 - How to Read This Dashboard

- **Panel title:** How to Read This Dashboard
- **Visualization type:** text
- **Purpose:** Use this dashboard to move from symptom to root cause. Start with downtime and failure Pareto, inspect the affected asset and work orders, then verify RCA, corrective action, PM revision, and post-action performance. Data source: dashboard navigation narrative.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 2 - Maintenance Status Scorecard

- **Panel title:** Maintenance Status Scorecard
- **Visualization type:** row
- **Purpose:** Section grouping for **Maintenance Status Scorecard**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 3 - Open Work Orders

- **Panel title:** Open Work Orders
- **Visualization type:** stat
- **Purpose:** Counts work orders in v_work_order_backlog, which excludes CLOSED and CANCELLED records, filtered by selected asset. Lower is generally better but priority and age matter more than count alone. Review critical work, overdue PM, and the asset master when backlog grows. Data source: v_work_order_backlog.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT count(*) FROM v_work_order_backlog WHERE ('$asset' = '%' OR asset_code = '$asset')
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** v_work_order_backlog

### Panel 4 - Critical Work Orders

- **Panel title:** Critical Work Orders
- **Visualization type:** stat
- **Purpose:** Counts currently open critical work orders from the curated critical-work view, filtered by asset. Any nonzero result requires prompt production-risk, response, assignment, and parts review. Use the asset reliability summary and underlying work-order context next. Data source: v_open_critical_work_orders.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT count(*) FROM v_open_critical_work_orders WHERE ('$asset' = '%' OR asset_code = '$asset')
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** v_open_critical_work_orders

### Panel 5 - Overdue PMs

- **Panel title:** Overdue PMs
- **Visualization type:** stat
- **Purpose:** Counts PM executions past due whose status is not COMPLETED or CANCELLED, filtered by asset. Zero is desired; overdue work on A or plant-critical assets deserves first escalation. Review the Overdue PM Execution List for plan, age, and criticality. Data source: v_overdue_pm.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT count(*) FROM v_overdue_pm WHERE ('$asset' = '%' OR asset_code = '$asset')
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** v_overdue_pm

### Panel 6 - PM Compliance

- **Panel title:** PM Compliance
- **Visualization type:** stat
- **Purpose:** Shows the latest monthly PM compliance: completed on or before due date / all PM executions scheduled that month. Higher is better; target is 98%. Low compliance increases future critical-asset failure exposure. Review the monthly trend and overdue list. Data source: v_pm_compliance_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT compliance_percent FROM v_pm_compliance_monthly ORDER BY period DESC LIMIT 1
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** v_pm_compliance_monthly

### Panel 7 - Repeat Failures

- **Panel title:** Repeat Failures
- **Visualization type:** stat
- **Purpose:** Shows the latest monthly count of failure events flagged repeat_failure. Lower is better; recurrence suggests symptoms or causes remain unresolved. Use the repeat asset/mode table, failure Pareto, and RCA panels to select action. Data source: v_repeat_failures_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT repeat_failure_count FROM v_repeat_failures_monthly ORDER BY period DESC LIMIT 1
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** v_repeat_failures_monthly

### Panel 8 - Open RCA Actions

- **Panel title:** Open RCA Actions
- **Visualization type:** stat
- **Purpose:** Counts open RCA corrective actions for the selected asset or plant. Each count represents known risk-reduction work not yet completed. Zero is desired only when no valid actions remain; investigate owners, due dates, status, and effectiveness in the Filler-201 action table. Data source: v_open_rca_actions.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT count(*) FROM v_open_rca_actions WHERE ('$asset' = '%' OR asset_code = '$asset')
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** v_open_rca_actions

### Panel 9 - Reliability Metrics by Asset

- **Panel title:** Reliability Metrics by Asset
- **Visualization type:** row
- **Purpose:** Section grouping for **Reliability Metrics by Asset**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 10 - MTTR by Asset (Worst to Best)

- **Panel title:** MTTR by Asset (Worst to Best)
- **Visualization type:** barchart
- **Purpose:** Ranks selected assets by MTTR minutes descending. MTTR is average completed repair duration; higher bars mean slower restoration and are worse. Investigate response, troubleshooting, skills, job plans, parts, and maintainability alongside downtime Pareto. Data source: v_mttr.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT asset_code AS "Asset", mttr_minutes AS "MTTR (min)" FROM v_mttr WHERE ('$asset' = '%' OR asset_code = '$asset') ORDER BY mttr_minutes DESC
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** v_mttr

### Panel 11 - MTBF by Asset (Lowest to Highest)

- **Panel title:** MTBF by Asset (Lowest to Highest)
- **Visualization type:** barchart
- **Purpose:** Ranks selected assets by MTBF hours ascending, putting the least reliable first. MTBF represents operating time between failures; higher is better. Low assets should be compared with repeat modes, PM coverage, and corrective actions. Data source: v_mtbf.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT asset_code AS "Asset", mtbf_hours AS "MTBF (hrs)" FROM v_mtbf WHERE ('$asset' = '%' OR asset_code = '$asset') ORDER BY mtbf_hours ASC
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** v_mtbf

### Panel 12 - Downtime by Asset (Pareto)

- **Panel title:** Downtime by Asset (Pareto)
- **Visualization type:** barchart
- **Purpose:** Ranks selected assets by recorded downtime minutes descending. The largest bars are the greatest time-recovery opportunities, but planned status and cause must be checked before calling loss maintenance-related. Use the failure-mode Pareto and asset work/RCA history next. Data source: v_downtime_by_asset.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT asset_code AS "Asset", downtime_minutes AS "Downtime (min)" FROM v_downtime_by_asset WHERE ('$asset' = '%' OR asset_code = '$asset') ORDER BY downtime_minutes DESC
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** v_downtime_by_asset

### Panel 13 - Failures by Asset

- **Panel title:** Failures by Asset
- **Visualization type:** barchart
- **Purpose:** Counts all recorded failure_events by selected asset and ranks highest first. One bar represents event frequency, not duration or cost. Frequent failures identify chronic exposure; compare with MTBF, downtime minutes, repeat flags, and failure modes before prioritizing. Data source: failure_events, assets.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT a.asset_code AS "Asset", count(*) AS "Failures" FROM failure_events f JOIN assets a USING(asset_id) WHERE ('$asset' = '%' OR a.asset_code = '$asset') GROUP BY a.asset_code ORDER BY count(*) DESC
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** assets, failure_events

### Panel 14 - Preventive Maintenance Performance

- **Panel title:** Preventive Maintenance Performance
- **Visualization type:** row
- **Purpose:** Section grouping for **Preventive Maintenance Performance**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 15 - PM Compliance Trend (Monthly)

- **Panel title:** PM Compliance Trend (Monthly)
- **Visualization type:** timeseries
- **Purpose:** Shows the latest monthly percentage of scheduled PM executions completed as required. Higher is better; performance below the 98% target signals growing preventive-work exposure. Review overdue PMs and critical-asset relevance next.  **Data source:** PostgreSQL v_pm_compliance_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT period AS time, compliance_percent AS "PM Compliance (%)", 98.0 AS "Target (98%)" FROM v_pm_compliance_monthly ORDER BY period
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** v_pm_compliance_monthly

### Panel 16 - PM Completion Status Breakdown

- **Panel title:** PM Completion Status Breakdown
- **Visualization type:** barchart
- **Purpose:** Counts PM execution records by current status. Each bar is a status category; large Scheduled/In Progress populations should be interpreted against due dates, while Completed reflects executed work.  **Data source:** PostgreSQL pm_executions.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT status AS "Status", count(*) AS "Executions" FROM pm_executions GROUP BY status ORDER BY count(*) DESC
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** pm_executions

### Panel 17 - Overdue PM Execution List

- **Panel title:** Overdue PM Execution List
- **Visualization type:** table
- **Purpose:** Each row is one PM execution past its scheduled date and not Completed or Cancelled, filtered by asset. Days Overdue drives descending order; criticality and age determine escalation priority.  **Data source:** PostgreSQL asset_criticality, assets, pm_executions, pm_plans.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT a.asset_code AS "Asset", p.pm_code AS "PM Plan", p.frequency AS "Frequency", e.scheduled_date AS "Due Date", (CURRENT_DATE - e.scheduled_date) AS "Days Overdue", ac.criticality_class AS "Priority" FROM pm_executions e JOIN pm_plans p USING(pm_plan_id) JOIN assets a USING(asset_id) JOIN asset_criticality ac USING(asset_id) WHERE e.status NOT IN ('COMPLETED', 'CANCELLED') AND e.scheduled_date < CURRENT_DATE AND ('$asset' = '%' OR a.asset_code = '$asset') ORDER BY (CURRENT_DATE - e.scheduled_date) DESC
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** asset_criticality, assets, pm_executions, pm_plans

### Panel 18 - Failure Analysis & Repeat Issues

- **Panel title:** Failure Analysis & Repeat Issues
- **Visualization type:** row
- **Purpose:** Section grouping for **Failure Analysis & Repeat Issues**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 19 - Failure Mode Pareto (Event Count)

- **Panel title:** Failure Mode Pareto (Event Count)
- **Visualization type:** barchart
- **Purpose:** Ranks failure modes by event count in descending order. Frequency Pareto highlights recurring problems, while the adjacent downtime Pareto shows duration impact; use both before selecting an RCA priority.  **Data source:** PostgreSQL v_downtime_by_failure_mode.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT failure_mode AS "Failure Mode", failure_count AS "Failures" FROM v_downtime_by_failure_mode ORDER BY failure_count DESC
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** v_downtime_by_failure_mode

### Panel 20 - Downtime by Failure Mode

- **Panel title:** Downtime by Failure Mode
- **Visualization type:** barchart
- **Purpose:** Ranks failure modes by associated downtime minutes in descending order. Use it to prioritize modes with the greatest time impact, then inspect affected assets, work orders, and RCA evidence.  **Data source:** PostgreSQL v_downtime_by_failure_mode.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT failure_mode AS "Failure Mode", downtime_minutes AS "Downtime (min)" FROM v_downtime_by_failure_mode ORDER BY downtime_minutes DESC
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** v_downtime_by_failure_mode

### Panel 21 - Repeat Failure Assets & Modes

- **Panel title:** Repeat Failure Assets & Modes
- **Visualization type:** table
- **Purpose:** Each row is an asset/failure-mode combination with more than one recorded event, filtered by selected asset. It shows event count, joined downtime minutes, and whether any event is flagged repeat, sorted highest count first. Repeated high-duration combinations should trigger RCA or effectiveness review. Data source: failure_events, downtime_events, assets.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT a.asset_code AS "Asset", f.failure_mode AS "Failure Mode", count(*) AS "Events", round(sum(EXTRACT(epoch FROM (COALESCE(d.downtime_end, now()) - d.downtime_start))/60.0), 0) AS "Total Downtime (min)", CASE WHEN count(*) FILTER (WHERE f.repeat_failure) > 0 THEN 'Repeat Problem' ELSE 'Single Event' END AS "Repeat Indicator" FROM failure_events f JOIN assets a USING(asset_id) LEFT JOIN downtime_events d USING(work_order_id) WHERE ('$asset' = '%' OR a.asset_code = '$asset') GROUP BY a.asset_code, f.failure_mode HAVING count(*) > 1 ORDER BY count(*) DESC
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** assets, downtime_events, failure_events

### Panel 22 - Filler-201 Case Study: Symptom Treatment to Root Cause Resolution

- **Panel title:** Filler-201 Case Study: Symptom Treatment to Root Cause Resolution
- **Visualization type:** row
- **Purpose:** Section grouping for **Filler-201 Case Study: Symptom Treatment to Root Cause Resolution**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 23 - Filler-201 Failure Timeline (Early Symptoms vs Post-RCA Fix)

- **Panel title:** Filler-201 Failure Timeline (Early Symptoms vs Post-RCA Fix)
- **Visualization type:** table
- **Purpose:** Each row is a chronological Filler-201 failure linked to its work order, downtime, and corrective action where available. Early realignment entries show symptom treatment; later engineering actions support the RCA effectiveness story.  **Data source:** PostgreSQL assets, corrective_actions, downtime_events, failure_events, rca_events, work_orders.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT f.failure_time AS "Failure Time", f.failure_mode AS "Failure Mode", round(EXTRACT(epoch FROM (d.downtime_end - d.downtime_start))/60.0, 0) AS "Downtime (min)", w.work_order_number AS "Work Order", COALESCE(c.action_description, 'Symptom correction / realignment') AS "Corrective Action" FROM failure_events f JOIN assets a USING(asset_id) JOIN work_orders w USING(work_order_id) LEFT JOIN downtime_events d USING(work_order_id) LEFT JOIN rca_events r USING(work_order_id) LEFT JOIN corrective_actions c USING(rca_event_id) WHERE a.asset_code='FILLER-201' ORDER BY f.failure_time ASC
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** assets, corrective_actions, downtime_events, failure_events, rca_events, work_orders

### Panel 24 - Filler-201 Monthly Downtime Trend

- **Panel title:** Filler-201 Monthly Downtime Trend
- **Visualization type:** timeseries
- **Purpose:** Sums Filler-201 downtime duration by calendar month. Declining values after the June 2026 RCA/PM revision support effectiveness; renewed increases would trigger verification follow-up.  **Data source:** PostgreSQL assets, downtime_events.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT date_trunc('month', d.downtime_start)::date AS time, round(sum(EXTRACT(epoch FROM (COALESCE(d.downtime_end, now()) - d.downtime_start))/60.0), 0) AS "Filler-201 Downtime (min)" FROM downtime_events d JOIN assets a USING(asset_id) WHERE a.asset_code='FILLER-201' GROUP BY 1 ORDER BY 1
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** assets, downtime_events

### Panel 25 - Filler-201 Root Cause Analysis (RCA)

- **Panel title:** Filler-201 Root Cause Analysis (RCA)
- **Visualization type:** table
- **Purpose:** Each row is a Filler-201 RCA record showing problem, determined root cause, method, dates, and status. Completed records should connect to corrective actions and PM revisions rather than remain isolated findings.  **Data source:** PostgreSQL assets, rca_events, work_orders.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT r.rca_number AS "RCA #", r.problem_statement AS "Problem Statement", r.root_cause AS "Root Cause", r.analysis_method AS "RCA Method", r.opened_at::date AS "Opened", r.completed_at::date AS "Completed", r.status AS "Status" FROM rca_events r JOIN work_orders w USING(work_order_id) JOIN assets a USING(asset_id) WHERE a.asset_code='FILLER-201' ORDER BY r.opened_at DESC
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** assets, rca_events, work_orders

### Panel 26 - Filler-201 Corrective Actions

- **Panel title:** Filler-201 Corrective Actions
- **Visualization type:** table
- **Purpose:** Each row is a Filler-201 RCA corrective action with owner, due date, completion date, and effectiveness verification, ordered by due date. Open, overdue, or unverified actions need follow-up; completed and verified actions should correspond to lower post-RCA downtime. Data source: corrective_actions, rca_events, work_orders, assets, employees.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT c.action_description AS "Corrective Action", e.first_name || ' ' || e.last_name AS "Owner", c.due_date AS "Due Date", c.completed_date AS "Completed Date", CASE WHEN c.verified_effectiveness THEN 'Yes' ELSE 'Pending' END AS "Verified Effective" FROM corrective_actions c JOIN rca_events r USING(rca_event_id) JOIN work_orders w USING(work_order_id) JOIN assets a USING(asset_id) LEFT JOIN employees e ON e.employee_id=c.owner_employee_id WHERE a.asset_code='FILLER-201' ORDER BY c.due_date ASC
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** assets, corrective_actions, employees, rca_events, work_orders

### Panel 27 - Filler-201 PM Revision (Before vs After)

- **Panel title:** Filler-201 PM Revision (Before vs After)
- **Visualization type:** table
- **Purpose:** Each row is one task in a Filler-201 weekly PM revision, ordered by revision and task sequence. Compare revisions to confirm RCA learning changed preventive work content.  **Data source:** PostgreSQL assets, pm_plan_revisions, pm_plans, pm_tasks.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT 'Rev ' || r.revision_number AS "Revision", r.effective_from AS "Effective From", t.sequence_number AS "Seq", t.task_description AS "PM Task Description", r.change_reason AS "Engineering Change Reason" FROM pm_plan_revisions r JOIN pm_plans p USING(pm_plan_id) JOIN assets a USING(asset_id) JOIN pm_tasks t USING(pm_plan_id, revision_number) WHERE a.asset_code='FILLER-201' AND p.pm_code LIKE '%WEEKLY' ORDER BY r.revision_number, t.sequence_number
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** assets, pm_plan_revisions, pm_plans, pm_tasks

### Panel 28 - Conveyor-201 Secondary Case Study & Capital Improvement Opportunity

- **Panel title:** Conveyor-201 Secondary Case Study & Capital Improvement Opportunity
- **Visualization type:** row
- **Purpose:** Section grouping for **Conveyor-201 Secondary Case Study & Capital Improvement Opportunity**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 29 - Conveyor-201 Repeat Belt Tracking Failures

- **Panel title:** Conveyor-201 Repeat Belt Tracking Failures
- **Visualization type:** table
- **Purpose:** Each row is a chronological Conveyor-201 belt/tracking failure with downtime, work-order description, and status. Repetition or long duration supports inspection of guide rollers, alignment, PM quality, or capital improvement.  **Data source:** PostgreSQL assets, downtime_events, failure_events, work_orders.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT f.failure_time::date AS "Date", f.failure_mode AS "Failure Mode", round(EXTRACT(epoch FROM (COALESCE(d.downtime_end, now()) - d.downtime_start))/60.0, 0) AS "Downtime (min)", w.title AS "Work Order Description", w.status AS "Status" FROM failure_events f JOIN assets a USING(asset_id) JOIN work_orders w USING(work_order_id) LEFT JOIN downtime_events d USING(work_order_id) WHERE a.asset_code='CONVEYOR-201' ORDER BY f.failure_time ASC
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** assets, downtime_events, failure_events, work_orders

### Panel 30 - Conveyor-201 Monthly Downtime Trend

- **Panel title:** Conveyor-201 Monthly Downtime Trend
- **Visualization type:** timeseries
- **Purpose:** Sums Conveyor-201 downtime minutes by month. Sustained decline indicates improving belt-tracking reliability; recurring peaks should be compared with the failure timeline and work-order status.  **Data source:** PostgreSQL assets, downtime_events.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT date_trunc('month', d.downtime_start)::date AS time, round(sum(EXTRACT(epoch FROM (COALESCE(d.downtime_end, now()) - d.downtime_start))/60.0), 0) AS "Conveyor-201 Downtime (min)" FROM downtime_events d JOIN assets a USING(asset_id) WHERE a.asset_code='CONVEYOR-201' GROUP BY 1 ORDER BY 1
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** assets, downtime_events

### Panel 31 - Plant-Wide Asset Reliability Master Summary

- **Panel title:** Plant-Wide Asset Reliability Master Summary
- **Visualization type:** row
- **Purpose:** Section grouping for **Plant-Wide Asset Reliability Master Summary**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 32 - Asset Reliability Master Summary

- **Panel title:** Asset Reliability Master Summary
- **Visualization type:** table
- **Purpose:** Each row is one asset summary filtered by selected asset, showing scope, criticality, uptime, failures, repeat failures, downtime, open work, and late PMs. Rows sort criticality then lowest uptime, surfacing high-risk poor performers. Use it to choose the next asset-level work, failure, or PM investigation. Data source: v_asset_reliability_summary.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT asset_name AS "Asset Name", line_scope AS "Line / Scope", criticality_class AS "Criticality", uptime_percent AS "Uptime (%)", failures AS "Total Failures", repeat_failures AS "Repeat Failures", downtime_minutes AS "Downtime (min)", open_work_orders AS "Open Work Orders", late_pm_count AS "Late PMs" FROM v_asset_reliability_summary WHERE ('$asset' = '%' OR asset_code = '$asset') ORDER BY criticality_class ASC, uptime_percent ASC
```
- **Drill-down:** Follow poor assets from Pareto to failure timeline, work/RCA/action/PM revision, then return to VP Operations.
- **PostgreSQL source view/table:** v_asset_reliability_summary

### Dashboard variables

- **$line - Production Line:** `SELECT 'All' AS __text, '%' AS __value UNION ALL SELECT name AS __text, name AS __value FROM production_lines ORDER BY 1`
- **$asset - Asset:** `SELECT asset_code AS __text, asset_code AS __value FROM assets a WHERE '$line' = '%' OR EXISTS (SELECT 1 FROM asset_line_relationships alr JOIN production_lines pl USING(line_id) WHERE alr.asset_id = a.asset_id AND (pl.name LIKE '$line' OR pl.line_code LIKE '$line')) ORDER BY asset_code`

### Dashboard links

- **VP Operations Overview:** /d/atx-vp-operations/vp-operations-overview
- **Staffing, Sanitation & Operational Risk:** /d/atx-operational-risk/staffing-sanitation-and-operational-risk
- **Production & OEE Performance:** /d/atx-production-oee/production-and-oee-performance

## 5. Staffing, Sanitation & Operational Risk

### Dashboard purpose

How to Read This Dashboard

Do people, coverage, shared assets, and equipment condition protect production?

This dashboard focuses on risks that may not appear first as maintenance failures: staffing gaps, sanitation findings, shared-asset conflicts, overtime, skill coverage, and utility-condition degradation.

### Interview question it answers

> Do we have the staffing, maintenance coverage, sanitation response, shared-equipment capacity, and asset condition required to protect production?

### Panel 1 - How to Read This Dashboard

- **Panel title:** How to Read This Dashboard
- **Visualization type:** text
- **Purpose:** This dashboard focuses on risks that may not appear first as maintenance failures: staffing gaps, sanitation findings, shared-asset conflicts, overtime, skill coverage, and utility-condition degradation. Use it to decide whether people, planned response, shared capacity, and predictive intervention can protect the next production window. Data source: dashboard navigation narrative.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 2 - Staffing Coverage Model & Sanitation Gap

- **Panel title:** Staffing Coverage Model & Sanitation Gap
- **Visualization type:** row
- **Purpose:** Section grouping for **Staffing Coverage Model & Sanitation Gap**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 3 - Production Shift A Maintenance Coverage

- **Panel title:** Production Shift A Maintenance Coverage
- **Visualization type:** stat
- **Purpose:** Shows the number of maintenance technicians assigned to the named production shift. The expected value is one; zero indicates no immediate maintenance coverage and values should be interpreted with skill coverage.  **Data source:** PostgreSQL v_shift_maintenance_coverage.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT maintenance_technicians FROM v_shift_maintenance_coverage WHERE shift_name='Production Shift A'
```
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** v_shift_maintenance_coverage

### Panel 4 - Production Shift B Maintenance Coverage

- **Panel title:** Production Shift B Maintenance Coverage
- **Visualization type:** stat
- **Purpose:** Shows the number of maintenance technicians assigned to the named production shift. The expected value is one; zero indicates no immediate maintenance coverage and values should be interpreted with skill coverage.  **Data source:** PostgreSQL v_shift_maintenance_coverage.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT maintenance_technicians FROM v_shift_maintenance_coverage WHERE shift_name='Production Shift B'
```
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** v_shift_maintenance_coverage

### Panel 5 - Sanitation Maintenance Coverage (Coverage Gap)

- **Panel title:** Sanitation Maintenance Coverage (Coverage Gap)
- **Visualization type:** stat
- **Purpose:** Shows maintenance technicians assigned to the sanitation shift. The designed value is zero, explicitly exposing a coverage gap—not a data error. Review sanitation findings, startup risk, overtime, and escalation planning.  **Data source:** PostgreSQL v_shift_maintenance_coverage.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT maintenance_technicians FROM v_shift_maintenance_coverage WHERE shift_name='Sanitation Shift'
```
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** v_shift_maintenance_coverage

### Panel 6 - Sanitation Findings & Startup Risk Workflow

- **Panel title:** Sanitation Findings & Startup Risk Workflow
- **Visualization type:** row
- **Purpose:** Section grouping for **Sanitation Findings & Startup Risk Workflow**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 7 - Open Sanitation Findings

- **Panel title:** Open Sanitation Findings
- **Visualization type:** stat
- **Purpose:** Counts sanitation findings not Resolved or Closed. A high count indicates unresolved conditions; review the prioritized findings table for startup and maintenance impact.  **Data source:** PostgreSQL sanitation_findings.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT count(*) FROM sanitation_findings WHERE status NOT IN ('RESOLVED', 'CLOSED')
```
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** sanitation_findings

### Panel 8 - Maintenance Required Findings

- **Panel title:** Maintenance Required Findings
- **Visualization type:** stat
- **Purpose:** Counts open sanitation findings flagged as requiring maintenance. These require work-order linkage or disposition; compare with available coverage and startup timing.  **Data source:** PostgreSQL sanitation_findings.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT count(*) FROM sanitation_findings WHERE maintenance_required AND status NOT IN ('RESOLVED', 'CLOSED')
```
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** sanitation_findings

### Panel 9 - Startup Risk Findings

- **Panel title:** Startup Risk Findings
- **Visualization type:** stat
- **Purpose:** Counts open sanitation findings flagged as potential startup risks. Any nonzero value deserves pre-start coordination so unresolved conditions do not delay production.  **Data source:** PostgreSQL sanitation_findings.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT count(*) FROM sanitation_findings WHERE startup_risk AND status NOT IN ('RESOLVED', 'CLOSED')
```
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** sanitation_findings

### Panel 10 - Monthly Sanitation Findings Trend

- **Panel title:** Monthly Sanitation Findings Trend
- **Visualization type:** timeseries
- **Purpose:** Counts sanitation findings by month, with maintenance-required and startup-risk subsets. Rising trends may indicate asset condition, cleaning damage, reporting improvement, or inadequate response; use the open table for current action.  **Data source:** PostgreSQL sanitation_findings.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT date_trunc('month', reported_at)::date AS time, count(*) AS "Total Findings", count(*) FILTER (WHERE maintenance_required) AS "Maintenance Required", count(*) FILTER (WHERE startup_risk) AS "Startup Risks" FROM sanitation_findings GROUP BY 1 ORDER BY 1
```
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** sanitation_findings

### Panel 11 - Open Sanitation Findings (Startup Risk Prioritized)

- **Panel title:** Open Sanitation Findings (Startup Risk Prioritized)
- **Visualization type:** table
- **Purpose:** Each row is one sanitation finding not RESOLVED or CLOSED, so it is a current open snapshot. Columns identify report date, asset, finding, priority, maintenance requirement, startup risk, linked work order, and status. Rows sort startup risks first, then newest report. Startup-risk findings without a work order or disposition require pre-start coordination. Data source: sanitation_findings, assets, work_orders.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT sf.reported_at::date AS "Date", a.asset_code AS "Asset", sf.description AS "Finding Description", sf.priority AS "Priority", CASE WHEN sf.maintenance_required THEN 'Yes' ELSE 'No' END AS "Maint Req", CASE WHEN sf.startup_risk THEN 'Yes' ELSE 'No' END AS "Startup Risk", COALESCE(w.work_order_number, 'None') AS "Work Order", sf.status AS "Status" FROM sanitation_findings sf JOIN assets a USING(asset_id) LEFT JOIN work_orders w USING(work_order_id) WHERE sf.status NOT IN ('RESOLVED', 'CLOSED') ORDER BY sf.startup_risk DESC, sf.reported_at DESC
```
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** assets, sanitation_findings, work_orders

### Panel 12 - Overtime Economics: Planned Maintenance vs Reactive Breakdowns

- **Panel title:** Overtime Economics: Planned Maintenance vs Reactive Breakdowns
- **Visualization type:** row
- **Purpose:** Section grouping for **Overtime Economics: Planned Maintenance vs Reactive Breakdowns**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 13 - Planned vs Reactive Overtime Spend

- **Panel title:** Planned vs Reactive Overtime Spend
- **Visualization type:** timeseries
- **Purpose:** Trends monthly planned and reactive maintenance overtime cost. Planned overtime can protect production windows; reactive overtime indicates breakdown-driven expense. A shift from reactive to planned is generally favorable when reliability improves.  **Data source:** PostgreSQL v_reactive_overtime_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT period AS time, reactive_overtime_cost AS "Reactive Overtime ($)", planned_overtime_cost AS "Planned Overtime ($)" FROM v_reactive_overtime_monthly ORDER BY period
```
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** v_reactive_overtime_monthly

### Panel 14 - Reactive Overtime Reduction Trend

- **Panel title:** Reactive Overtime Reduction Trend
- **Visualization type:** timeseries
- **Purpose:** Trends monthly reactive overtime cost only. Lower is better when achieved without increasing unresolved risk; compare with downtime, PM compliance, and planned overtime.  **Data source:** PostgreSQL v_reactive_overtime_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT period AS time, reactive_overtime_cost AS "Reactive Overtime ($)" FROM v_reactive_overtime_monthly ORDER BY period
```
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** v_reactive_overtime_monthly

### Panel 15 - Technician Capability & Skills Matrix

- **Panel title:** Technician Capability & Skills Matrix
- **Visualization type:** row
- **Purpose:** Section grouping for **Technician Capability & Skills Matrix**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 16 - Maintenance Technician Skills Matrix

- **Panel title:** Maintenance Technician Skills Matrix
- **Visualization type:** table
- **Purpose:** Each row is one maintenance skill with Shift A and Shift B proficiency, count of technicians independently qualified at level 3+, and critical-skill flag. Uneven levels show complementary strengths; zero/one qualified technician identifies training, absence, and response risk. Use the critical-skill risk table for escalation. Data source: v_technician_skill_coverage.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT skill AS "Skill Area", shift_a_level AS "Shift A Level", shift_b_level AS "Shift B Level", independently_qualified AS "Independent Techs (Level 3+)", CASE WHEN critical_skill THEN 'Yes' ELSE 'No' END AS "Critical Skill" FROM v_technician_skill_coverage ORDER BY skill
```
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** v_technician_skill_coverage

### Panel 17 - Critical Equipment Skill Coverage & Single-Point Risks

- **Panel title:** Critical Equipment Skill Coverage & Single-Point Risks
- **Visualization type:** table
- **Purpose:** Each row is one critical skill, showing qualified technician count, maximum proficiency by production shift, and risk classification. Full Coverage means at least two level-3+ technicians; Single Tech Risk means one; Coverage Gap means none. Address gaps through training, coverage, or external support planning. Data source: skills, employee_skills, employee_shift_assignments, shifts.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT sk.name AS "Skill Area", count(*) FILTER (WHERE es.proficiency_level >= 3) AS "Qualified Techs (Level 3+)", max(es.proficiency_level) FILTER (WHERE s.name='Production Shift A') AS "Shift A Max Level", max(es.proficiency_level) FILTER (WHERE s.name='Production Shift B') AS "Shift B Max Level", CASE WHEN count(*) FILTER (WHERE es.proficiency_level >= 3) >= 2 THEN 'Full Coverage' WHEN count(*) FILTER (WHERE es.proficiency_level >= 3) = 1 THEN 'Single Tech Risk' ELSE 'Coverage Gap' END AS "Risk Assessment" FROM skills sk LEFT JOIN employee_skills es USING(skill_id) LEFT JOIN employee_shift_assignments esa ON esa.employee_id=es.employee_id AND esa.is_primary AND esa.effective_to IS NULL LEFT JOIN shifts s USING(shift_id) WHERE sk.critical_skill GROUP BY sk.skill_id, sk.name ORDER BY sk.name
```
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** employee_shift_assignments, employee_skills, shifts, skills

### Panel 18 - Critical Spare Parts Management

- **Panel title:** Critical Spare Parts Management
- **Visualization type:** row
- **Purpose:** Section grouping for **Critical Spare Parts Management**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 19 - Critical Spare Availability — Target ≥98%

- **Panel title:** Critical Spare Availability — Target ≥98%
- **Visualization type:** stat
- **Purpose:** Shows the latest availability percentage for critical spare parts, or lists critical inventory by supported asset. Shortages below minimum stock and long lead times increase restoration risk; review affected critical assets and work backlog.  **Data source:** PostgreSQL v_critical_spares_monthly.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT availability_percent FROM v_critical_spares_monthly ORDER BY period DESC LIMIT 1
```
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** v_critical_spares_monthly

### Panel 20 - Critical Spare Inventory & Shortage Status

- **Panel title:** Critical Spare Inventory & Shortage Status
- **Visualization type:** table
- **Purpose:** Each row is one critical part aggregated across all supported assets. Critical means the part or asset-part relationship is flagged critical. Columns show supported assets, on-hand, minimum, lead time, and Below Minimum/Adequate status; shortages sort first. Below-minimum long-lead parts supporting critical/shared assets require replenishment. Data source: parts, asset_parts, assets.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT p.part_number AS "Part Number", p.description AS "Description", string_agg(DISTINCT a.asset_code, ', ' ORDER BY a.asset_code) AS "Supported Assets", p.quantity_on_hand AS "On Hand", p.minimum_quantity AS "Minimum", p.lead_time_days AS "Lead Time (Days)", CASE WHEN p.quantity_on_hand < p.minimum_quantity THEN 'Below Minimum (Risk)' ELSE 'Adequate' END AS "Status" FROM parts p JOIN asset_parts ap USING(part_id) JOIN assets a USING(asset_id) WHERE p.critical_spare OR ap.critical_for_asset GROUP BY p.part_id, p.part_number, p.description, p.quantity_on_hand, p.minimum_quantity, p.lead_time_days ORDER BY (p.quantity_on_hand < p.minimum_quantity) DESC, p.part_number
```
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** asset_parts, assets, parts

### Panel 21 - Air-Comp-001 Predictive Condition Monitoring (Plant-Wide Utility Risk)

- **Panel title:** Air-Comp-001 Predictive Condition Monitoring (Plant-Wide Utility Risk)
- **Visualization type:** row
- **Purpose:** Section grouping for **Air-Comp-001 Predictive Condition Monitoring (Plant-Wide Utility Risk)**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 22 - Air-Comp-001 Vibration — Degradation Before Failure (mm/s)

- **Panel title:** Air-Comp-001 Vibration — Degradation Before Failure (mm/s)
- **Visualization type:** timeseries
- **Purpose:** Trends all seeded Air-Comp-001 vibration readings with 2.8 mm/s warning and 4.5 mm/s alarm references. Rising or threshold-crossing vibration indicates degradation before functional failure. Both lines depend simultaneously on this utility, so predictive sanitation-window intervention is high priority; no piece-rate OEE is assigned. Data source: v_condition_measurements.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT time, numeric_value AS "Vibration (mm/s)", warning_threshold AS "Warning Threshold (2.8 mm/s)", alarm_threshold AS "Alarm Threshold (4.5 mm/s)" FROM v_condition_measurements WHERE asset_code='AIR-COMP-001' AND measurement_type='VIBRATION' ORDER BY time
```
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** v_condition_measurements

### Panel 23 - Air-Comp-001 Temperature, Current & Pressure

- **Panel title:** Air-Comp-001 Temperature, Current & Pressure
- **Visualization type:** timeseries
- **Purpose:** Trends all seeded Air-Comp-001 discharge temperature, motor current, and discharge pressure observations. These signals have different engineering units and should be interpreted by series, not compared numerically to one another. Sustained excursions or correlated changes support condition investigation with vibration and planned intervention. Data source: v_condition_measurements.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT time, measurement_type AS metric, numeric_value AS value FROM v_condition_measurements WHERE asset_code='AIR-COMP-001' AND measurement_type IN ('DISCHARGE_TEMPERATURE', 'MOTOR_CURRENT', 'DISCHARGE_PRESSURE') ORDER BY time, measurement_type
```
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** v_condition_measurements

### Panel 24 - Air-Comp-001 Simultaneous Dual-Line Dependency & Planned Intervention

- **Panel title:** Air-Comp-001 Simultaneous Dual-Line Dependency & Planned Intervention
- **Visualization type:** table
- **Purpose:** The single current narrative row identifies Air-Comp-001 criticality, both dependent lines, simultaneous dependency, detected degradation, and planned sanitation-window mitigation. It excludes unrelated assets. Any unplanned loss threatens both lines, which justifies predictive priority without utility OEE. Data source: assets, asset_criticality, asset_line_relationships, production_lines.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT a.asset_code AS "Asset", ac.criticality_class AS "Criticality", string_agg(DISTINCT l.name, ', ' ORDER BY l.name) AS "Dependent Production Lines", 'SIMULTANEOUS_DEPENDENCY' AS "Plant Dependency", 'Degradation detected before failure (vibration 1.63 -> 3.13 mm/s)' AS "Condition Assessment", 'Scheduled planned intervention during sanitation window' AS "Mitigation Action" FROM assets a JOIN asset_criticality ac USING(asset_id) JOIN asset_line_relationships alr USING(asset_id) JOIN production_lines l USING(line_id) WHERE a.asset_code='AIR-COMP-001' GROUP BY a.asset_code, ac.criticality_class
```
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** asset_criticality, asset_line_relationships, assets, production_lines

### Panel 25 - Blender-001 Shared Asset Production Risk

- **Panel title:** Blender-001 Shared Asset Production Risk
- **Visualization type:** row
- **Purpose:** Section grouping for **Blender-001 Shared Asset Production Risk**. Read the panels below it together before drilling to the next numbered section or linked dashboard.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation:** Narrative or section grouping; no KPI calculation.
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** Dashboard narrative / no PostgreSQL query

### Panel 26 - Blender-001 Sequential Line 1 & Line 2 Production Schedule

- **Panel title:** Blender-001 Sequential Line 1 & Line 2 Production Schedule
- **Visualization type:** table
- **Purpose:** Each row is one Blender-001 scheduled production slot, ordered from earliest to latest, with order, assigned line, start/end, and status. Blender allocation is sequential; overlapping or delayed slots can starve the next line. Coordinate the current and next line when a slot changes. Data source: asset_production_schedule, assets, production_lines.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT aps.production_order AS "Production Order", l.name AS "Scheduled Line", aps.scheduled_start AS "Start Time", aps.scheduled_end AS "End Time", aps.status AS "Schedule Status" FROM asset_production_schedule aps JOIN production_lines l USING(line_id) JOIN assets a USING(asset_id) WHERE a.asset_code='BLENDER-001' ORDER BY aps.scheduled_start ASC
```
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** asset_production_schedule, assets, production_lines

### Panel 27 - Blender-001 Shared Asset Failure & Future Slot Risk

- **Panel title:** Blender-001 Shared Asset Failure & Future Slot Risk
- **Visualization type:** table
- **Purpose:** Each historical row is one Blender-001 failure showing failure time, currently affected line, immediate delay, future line at risk, projected delay, and estimated availability, newest first. Large current or projected delays require cross-line schedule and maintenance coordination. Data source: v_blender_shared_risk_history.
- **Data represented:** The value, row, bar, or trend series described above, using the exact selected fields and inclusion rules in the panel SQL below.
- **Formula / aggregation:** Defined by the exact panel SQL below; view-backed formulas are identified in the panel description and source view.
- **Interpretation:** Apply the stated high/low direction, target, status, trend, or ordering guidance before assigning cause.
- **Management significance:** Use the operational consequence and escalation guidance in the description to select the next action.
- **Calculation, inclusion, and ordering:** The exact curated query below defines the aggregation, filters, time period, grouping, and sort. Dashboard variables apply where shown.
- **Exact panel SQL:**

```sql
SELECT failure_time AS "Failure Time", current_impacted_line AS "Current Impacted Line", immediate_delay_minutes AS "Immediate Delay (min)", future_line_at_risk AS "Future Line at Risk", projected_future_delay_minutes AS "Projected Delay (min)", estimated_available_at AS "Estimated Available" FROM v_blender_shared_risk_history ORDER BY failure_time DESC
```
- **Drill-down:** Follow coverage, finding, inventory, schedule, or condition exceptions to Maintenance Reliability or VP Operations for action ownership.
- **PostgreSQL source view/table:** v_blender_shared_risk_history

### Dashboard variables

- No dashboard variables.

### Dashboard links

- **VP Operations Overview:** /d/atx-vp-operations/vp-operations-overview
- **Maintenance Reliability:** /d/atx-maintenance-reliability/maintenance-reliability
- **Production & OEE Performance:** /d/atx-production-oee/production-and-oee-performance

## Recommended Interview Navigation

### Full demonstration - 5 to 10 minutes

1. Start at **VP Operations Overview** and answer what needs leadership attention using scorecards, trends, Pareto, and current-risk tables.
2. Open **Production & OEE Performance**. Compare schedule execution and line OEE, then explain Availability, Performance, Quality, and production-time loss categories.
3. Use the Line 2 equipment contributors table to open **Filler-201 Equipment OEE Detail**. Explain Scheduled Utilization separately from OEE.
4. Follow time accounting to Stop Loss, sensor evidence, and the downtime/work-order/RCA/corrective-action/PM-revision trace.
5. Open **Maintenance Reliability** to show plant-wide downtime, MTTR, MTBF, repeat-failure Pareto, overdue PMs, and corrective-action effectiveness.
6. Finish at **Staffing, Sanitation & Operational Risk** to show the 1/1/0 coverage model, sanitation response, skills, spares, Blender scheduling, and Air-Comp predictive risk.
7. Return to **VP Operations Overview** and summarize production capacity, reliability actions, and accountable next steps.

### Filler-201 deep-dive - 2 to 3 minutes

1. Select **FILLER-201** on Equipment OEE Detail.
2. Distinguish Scheduled Utilization from Equipment OEE, then identify the weakest OEE component.
3. Show calendar, scheduled production, planned changeover, unscheduled downtime, and runtime.
4. Use Stop Reason Pareto to distinguish unclassified, dependency, and confirmed photoeye maintenance loss. Reinforce: a stopped machine is not automatically a maintenance problem.
5. Correlate run/fault, counter, rate, cycle, and photoeye evidence with the stopped interval.
6. Trace downtime -> work order -> failure mode -> RCA -> bracket/locking corrective action -> PM revision.
7. Close with the pre/post RCA reduction in stop count, total Stop Loss, photoeye minutes, and average duration.
