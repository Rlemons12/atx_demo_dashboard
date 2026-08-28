# Maintenance Manager Interview Demo
## PostgreSQL + Grafana Reliability Management Demonstration

**Status:** Working Design Document  
**Purpose:** Interview demonstration for a Maintenance Manager role reporting to the Vice President of Operations
**Primary Objective:** Demonstrate how a structured, data-driven maintenance program can move a small manufacturing operation from reactive maintenance toward preventive and predictive maintenance while improving uptime, maintenance visibility, spare-parts readiness, team capability, and production support.

---

# 1. Demo Purpose

This demo is intended to show a Vice President of Operations how maintenance can be managed as an operational reliability system rather than only as a repair function.

The demo will use:

- PostgreSQL as the maintenance and production data store.
- Grafana for operational and maintenance KPI dashboards.
- A small but realistic manufacturing environment.
- Historical seeded data to demonstrate trends and improvement.
- Preventive Maintenance (PM), downtime, work orders, RCA, spare parts, staffing, sanitation findings, and asset criticality.
- Shared production and utility equipment to demonstrate production dependencies.

The primary message of the demo is:

> Maintenance should not simply repair equipment. Maintenance should identify production risk, prevent repeat failures, improve reliability, protect production capacity, and provide Operations with measurable information for decision-making.

---

# 2. Job Requirements Represented by the Demo

The demo should visibly support the following job expectations:

## Preventive and Predictive Maintenance

- Documented PM program for 100% of critical production assets.
- Asset registry with equipment criticality ranking.
- PM schedule compliance target of at least 98%.
- Reduction in unplanned downtime.
- Reduction in emergency work orders.
- Transition from reactive to preventive and predictive maintenance.

## Work Order and Maintenance Tracking

- Structured work order system.
- 100% maintenance work documented.
- Baseline downtime, response time, MTTR, and MTBF.
- MTTR improvement target.
- MTBF improvement target.
- Work order closure rate.
- Emergency work percentage.

## Equipment Reliability and Uptime

- Production uptime target of at least 95%.
- Critical breakdown response target.
- Repeat failure reduction.
- Food safety and maintenance-related audit compliance.

## Budget and Cost Management

- Maintenance budget tracking.
- Parts-spend visibility.
- Critical spare availability.
- Reactive maintenance cost reduction.
- Planned versus reactive overtime.

## Team Leadership and Development

- Technician skill-gap analysis.
- Cross-training visibility.
- Weekly KPI review.
- Maintenance coverage by shift.
- Operations support visibility.

## Capital and Facility Projects

- Project ROI.
- Production impact analysis.
- Reliability-driven capital recommendations.

## Ongoing Expectations

- Daily production communication.
- Weekly KPI dashboard.
- RCA for major failures.
- Monthly downtime and reliability reporting.

---

# 3. Demo Plant Scope

The demo will represent one manufacturing facility.

## Facility

- **Sites:** 1
- **Production Lines:** 2
- **Production Shifts:** 2
- **Sanitation Shifts:** 1
- **Total Employees:** Approximately 10
- **Maintenance Technicians:** 2
- **Normal Maintenance Coverage During Sanitation:** None

---

# 4. Shift Structure

The initial demo shift schedule will be:

| Shift | Hours | Function | Maintenance Coverage |
|---|---|---|---|
| Production Shift A | 6:00 AM - 2:00 PM | Production | 1 Maintenance Technician |
| Production Shift B | 2:00 PM - 10:00 PM | Production | 1 Maintenance Technician |
| Sanitation Shift | 10:00 PM - 6:00 AM | Cleaning / Sanitation | No normal Maintenance Technician |

The exact shift times may be changed later without changing the design.

---

# 5. Employee Structure

A practical initial employee count is approximately 10.

## Production Shift A

- 1 Maintenance Technician
- 1 Line 1 Operator
- 1 Line 2 Operator
- 1 Production Lead

## Production Shift B

- 1 Maintenance Technician
- 1 Line 1 Operator
- 1 Line 2 Operator
- 1 Production Lead

## Sanitation Shift

- 1 Sanitation Lead
- 1 Sanitation Technician

---

# 6. Maintenance Staffing Model

Only the two production shifts have dedicated maintenance coverage.

This creates an intentional operational risk that can be demonstrated.

## Shift A Technician

Example capability profile:

| Skill | Level |
|---|---:|
| Mechanical | 4 |
| Electrical | 3 |
| PLC | 2 |
| Pneumatics | 4 |
| Fillers | 4 |
| Mixers | 3 |
| Conveyors | 4 |
| Labelers | 3 |

## Shift B Technician

Example capability profile:

| Skill | Level |
|---|---:|
| Mechanical | 3 |
| Electrical | 4 |
| PLC | 3 |
| Pneumatics | 3 |
| Fillers | 3 |
| Mixers | 4 |
| Conveyors | 3 |
| Labelers | 4 |

The technicians should intentionally have different strengths so the demo can show:

- Skill gaps.
- Cross-training needs.
- Shift coverage risk.
- Critical equipment coverage.
- Training priorities.

---

# 7. Production Assets

The demo will contain 10 total assets.

## Line 1 Dedicated Equipment

1. Mixer-101
2. Conveyor-101
3. Filler-101
4. Labeler-101

## Line 2 Dedicated Equipment

5. Mixer-201
6. Conveyor-201
7. Filler-201
8. Labeler-201

## Shared Production Equipment

9. Blender-001

## Shared Utility Equipment

10. Air-Comp-001

---

# 8. Asset Relationship Types

The demo should demonstrate three different equipment dependency models.

## 8.1 Dedicated Asset

Example:

- Filler-101 -> Line 1 only
- Filler-201 -> Line 2 only

A failure normally affects one production line.

## 8.2 Shared Utility Asset

**Air-Comp-001** provides plant compressed air to both production lines simultaneously.

Conceptually:

```text
                 AIR-COMP-001
                      |
              Compressed Air Header
                 /           \
             Line 1         Line 2
```

If the compressor fails, both lines may be affected.

This makes it a plant-critical asset even if it has relatively few failures.

## 8.3 Shared Scheduled Production Asset

**Blender-001** is used by both lines, but not at the same time.

Example:

```text
06:00 - 09:00   Blender-001 -> Line 1
09:00 - 12:00   Blender-001 -> Line 2
12:00 - 14:00   Blender-001 -> Line 1
```

A failure can therefore create:

- Immediate production loss for the line currently using the asset.
- Future production risk for the other line.
- Scheduling conflicts.
- A need for Operations and Maintenance coordination.

---

# 9. Asset Criticality Concept

Criticality should be based on business and production impact rather than failure frequency alone.

Potential criticality factors:

- Production impact.
- Number of dependent lines.
- Food-safety impact.
- Safety impact.
- Quality impact.
- Redundancy.
- Repair time.
- Spare-parts lead time.
- Cost of downtime.
- Likelihood of repeat failure.

Example classifications:

| Asset | Asset Type | Production Dependency | Example Criticality |
|---|---|---|---|
| Mixer-101 | Dedicated | Line 1 | B |
| Conveyor-101 | Dedicated | Line 1 | B |
| Filler-101 | Dedicated | Line 1 | A |
| Labeler-101 | Dedicated | Line 1 | B |
| Mixer-201 | Dedicated | Line 2 | B |
| Conveyor-201 | Dedicated | Line 2 | B |
| Filler-201 | Dedicated | Line 2 | A |
| Labeler-201 | Dedicated | Line 2 | B |
| Blender-001 | Shared Production | Lines 1 + 2 sequentially | A |
| Air-Comp-001 | Shared Utility | Lines 1 + 2 simultaneously | Plant Critical |

---

# 10. Planned Reliability Story

The demo should not show a perfect plant.

It should show a maintenance organization improving over time.

## Baseline Example

| KPI | Baseline |
|---|---:|
| Uptime | 89.8% |
| PM Compliance | 72% |
| Emergency Work Orders | 48% |
| MTTR | 81 minutes |
| MTBF | 35 hours |
| Critical Spare Availability | 83% |
| Repeat Failures | 11/month |

## Current Example

| KPI | Current |
|---|---:|
| Uptime | 94.8% |
| PM Compliance | 96% |
| Emergency Work Orders | 31% |
| MTTR | 70 minutes |
| MTBF | 41 hours |
| Critical Spare Availability | 97% |
| Repeat Failures | 7/month |

## Target

| KPI | Target |
|---|---:|
| Uptime | >= 95% |
| PM Compliance | >= 98% |
| Emergency Work Orders | < 30% |
| MTTR | -15% from baseline |
| MTBF | +20% from baseline |
| Critical Spare Availability | >= 98% |
| Repeat Failures | -30% |
| Work Order Closure Rate | >= 95% |

---

# 11. Line Reliability Story

Line 1 should be relatively healthy.

Example:

| Asset | Uptime |
|---|---:|
| Mixer-101 | 97.9% |
| Conveyor-101 | 97.3% |
| Filler-101 | 95.8% |
| Labeler-101 | 98.2% |

Line 1 overall uptime should be approximately 97%.

Line 2 should contain the major demo reliability problem.

Example:

| Asset | Uptime |
|---|---:|
| Mixer-201 | 96.9% |
| Conveyor-201 | 92.8% |
| Filler-201 | 89.6% |
| Labeler-201 | 97.1% |

Line 2 overall uptime should be lower than Line 1.

This allows the demo to show how a plant-level KPI can hide equipment-level problems.

---

# 12. Primary Demo Failure Scenario

Filler-201 will be the main repeat-failure example.

Example historical failures:

| Date | Failure | Downtime |
|---|---|---:|
| Aug 3 | Photoeye misalignment | 35 min |
| Aug 9 | Photoeye misalignment | 42 min |
| Aug 16 | Photoeye signal fault | 51 min |
| Aug 23 | Photoeye mounting failure | 67 min |

The maintenance work initially fixes symptoms by realigning the sensor.

The RCA later identifies the underlying issue:

- Vibration loosens sensor mounting hardware.
- Mounting hardware lacks appropriate locking.
- The weekly PM checks sensor operation but not mounting security.

Corrective actions:

1. Replace damaged sensor bracket.
2. Install locking hardware.
3. Update weekly PM.
4. Inspect similar machines.
5. Add bracket and sensor assembly to reliability review.
6. Verify effectiveness through future failure data.

This demonstrates:

```text
Failure
  ->
Work Order
  ->
Downtime Record
  ->
RCA
  ->
Corrective Action
  ->
PM Revision
  ->
Future KPI Measurement
```

---

# 13. Secondary Demo Failure Scenario

Conveyor-201 can have a recurring belt-tracking issue.

Example:

- 3 failures in 60 days.
- 112 minutes total downtime.
- Worn guide roller.
- Alignment issue.
- PM interval or PM task quality may need revision.

This creates a second failure mode for Pareto analysis.

---

# 14. Shared Blender Scenario

Blender-001 should demonstrate production scheduling risk.

Example:

```text
06:00 - 09:00 -> Line 1
09:00 - 12:00 -> Line 2
12:00 - 14:00 -> Line 1
```

If Blender-001 fails at 08:15 and the estimated repair time is 90 minutes:

- Line 1 immediately stops.
- Line 2 is still running.
- Line 2 becomes at risk because its blender window begins at 09:00.
- Estimated return to service is 09:45.
- Projected Line 2 delay is 45 minutes.

Grafana should be able to distinguish:

- Current production impact.
- Upcoming production risk.
- Shared-equipment schedule dependency.

---

# 15. Shared Air Compressor Scenario

Air-Comp-001 supports both lines simultaneously.

Example condition data:

- Motor vibration.
- Outlet temperature.
- Motor current.
- Discharge pressure.
- Operating hours.

Example trend:

| Month | Vibration |
|---|---:|
| May | 1.9 mm/s |
| June | 2.1 mm/s |
| July | 2.5 mm/s |
| August | 3.2 mm/s |

The compressor may still be running normally, but rising vibration creates a predictive maintenance warning.

Because both lines depend on the compressor, maintenance priority should be elevated.

This allows the demo to show:

- Predictive maintenance.
- Plant-wide asset dependency.
- Risk-based maintenance prioritization.
- Planned repair during sanitation.

---

# 16. Sanitation Integration

Sanitation should be part of the reliability process rather than a disconnected shift.

Example sanitation findings:

| Finding | Asset | Condition | Priority |
|---|---|---|---|
| SAN-001 | Filler-101 | Loose guard fastener | Low |
| SAN-002 | Conveyor-201 | Damaged belt edge | High |
| SAN-003 | Filler-201 | Product buildup near sensor bracket | Medium |
| SAN-004 | Mixer-101 | Minor seal leak | Medium |

Sanitation findings can create maintenance requests or work orders.

Workflow:

```text
Sanitation Finding
       ->
Maintenance Request
       ->
Work Order
       ->
Repair / Inspection
       ->
PM or RCA Update if Required
```

The system should also track:

- Findings discovered during sanitation.
- Findings requiring maintenance response.
- Startup delay risk.
- Startup delays caused by unresolved findings.
- Maintenance overtime used to address planned sanitation-window work.

---

# 17. Planned Versus Reactive Overtime

The demo should distinguish between bad overtime and useful overtime.

Reactive overtime:

- Caused by breakdowns.
- Unplanned.
- Often expensive.
- Often disruptive.

Planned overtime:

- Scheduled for high-risk maintenance.
- May occur during sanitation or planned downtime.
- Can prevent future production loss.

Example:

Air-Comp-001 bearing inspection during sanitation:

```text
10:30 PM - 1:00 AM
Planned maintenance
Shift B technician extends shift
```

This supports the job objective of reducing overtime caused by reactive breakdowns rather than treating all overtime as undesirable.

---

# 18. PM Strategy

Every asset will have PMs at these five frequencies:

1. Weekly
2. Biweekly
3. Monthly
4. Quarterly
5. Semiannual

With 10 assets:

- 10 Weekly PM Plans
- 10 Biweekly PM Plans
- 10 Monthly PM Plans
- 10 Quarterly PM Plans
- 10 Semiannual PM Plans

**Total PM Plans: 50**

Each plan should generally contain 3-6 tasks.

---

# 19. Spare Parts Strategy

Each asset should have a short spare-parts list of approximately 4-6 parts.

Parts should be stored centrally and linked to assets because a single spare may support more than one machine.

Example:

```text
Photoelectric Sensor PE-01
  -> Filler-101
  -> Filler-201
```

This allows the demo to answer:

- Which assets depend on this part?
- Is the part critical?
- What is current on-hand quantity?
- What is minimum stock?
- What is lead time?
- Does stock cover all critical equipment?
- What production risk exists if the part is unavailable?

---

# 20. PM and Spare Parts by Asset

## 20.1 Mixer-101 / Mixer-201

### Spare Parts

- Motor contactor.
- Drive belt.
- Shaft seal kit.
- Mixing shaft bearing.
- Proximity sensor.
- VFD cooling fan.

### Weekly PM

- Inspect for product buildup.
- Check unusual noise or vibration.
- Inspect guards and fasteners.
- Check shaft seal for leakage.
- Verify emergency stop operation.

### Biweekly PM

- Inspect drive belt condition and tension.
- Inspect motor mounting hardware.
- Check sensor alignment.
- Inspect electrical cables and connectors.

### Monthly PM

- Lubricate bearings where applicable.
- Inspect coupling and shaft alignment.
- Check motor current against baseline.
- Inspect VFD fault history.
- Check gearbox oil level.

### Quarterly PM

- Inspect gearbox oil condition.
- Check motor insulation condition.
- Verify safety interlocks.
- Inspect internal electrical connections.
- Check bearing vibration trend.

### Semiannual PM

- Replace gearbox oil where required.
- Detailed motor inspection.
- Inspect or replace worn seals.
- Verify shaft alignment.
- Full safety circuit verification.
- Review PM effectiveness against failure history.

---

## 20.2 Conveyor-101 / Conveyor-201

### Spare Parts

- Conveyor belt.
- Drive roller bearing.
- Idler roller.
- Gearmotor.
- Belt tracking sensor.
- Photoelectric sensor.

### Weekly PM

- Inspect belt tracking.
- Inspect belt damage and wear.
- Check guards.
- Inspect rollers.
- Check for unusual vibration or noise.

### Biweekly PM

- Check belt tension.
- Inspect guide rails.
- Inspect sensor alignment.
- Check roller mounting hardware.

### Monthly PM

- Lubricate bearings where required.
- Inspect drive chain or drive belt.
- Inspect gearmotor.
- Check motor current.
- Inspect electrical connections.

### Quarterly PM

- Check pulley and roller alignment.
- Inspect gearbox oil.
- Inspect frame fasteners.
- Verify safety devices.
- Trend drive assembly vibration.

### Semiannual PM

- Detailed belt inspection.
- Assess belt replacement need.
- Inspect drive gearbox.
- Inspect all bearings.
- Verify full alignment.
- Inspect wiring and control enclosure.
- Review recurring belt-tracking failures.

---

## 20.3 Filler-101 / Filler-201

### Spare Parts

- Photoelectric sensor.
- Sensor mounting bracket.
- Pneumatic solenoid valve.
- Cylinder seal kit.
- Fill nozzle seal kit.
- Proximity sensor.

### Weekly PM

- Inspect photoeyes.
- Check sensor mounts.
- Inspect pneumatic tubing.
- Inspect fill nozzles.
- Verify guards and interlocks.
- Check for air leaks.

### Biweekly PM

- Verify sensor alignment.
- Inspect pneumatic cylinders.
- Check solenoid valve operation.
- Inspect mounting hardware.
- Check regulator pressure.

### Monthly PM

- Inspect drive system.
- Check bearing condition.
- Inspect electrical connections.
- Check motor current.
- Inspect valves and fittings.
- Review fault history.

### Quarterly PM

- Inspect control cabinet.
- Verify safety circuits.
- Check pneumatic leakage rate.
- Inspect actuator wear.
- Perform vibration checks.
- Verify fill sequence timing.

### Semiannual PM

- Replace critical seals.
- Inspect or rebuild selected pneumatic valves.
- Detailed drive inspection.
- Calibrate sensors where applicable.
- Verify machine alignment.
- Review PM effectiveness against failure history.

### Filler-201 RCA PM Revision

After the repeat sensor failure RCA, the weekly PM should be revised to explicitly include:

- Verify sensor bracket security.
- Verify locking hardware is present and secure.
- Check bracket for fatigue or damage.
- Confirm sensor alignment after bracket inspection.

---

## 20.4 Labeler-101 / Labeler-201

### Spare Parts

- Label sensor.
- Drive belt.
- Print head or print roller.
- Applicator roller.
- Proximity sensor.
- Motor or drive fuse.

### Weekly PM

- Clean label sensor.
- Inspect applicator rollers.
- Check label tracking.
- Inspect belts.
- Verify guards.

### Biweekly PM

- Inspect drive belt tension.
- Check sensor alignment.
- Inspect peel plate.
- Check mounting fasteners.

### Monthly PM

- Inspect drive motor.
- Check bearings.
- Inspect electrical connections.
- Review fault history.
- Check encoder operation.

### Quarterly PM

- Inspect internal control panel.
- Check motor current.
- Inspect complete label path.
- Verify safety devices.
- Inspect drive assembly.

### Semiannual PM

- Replace worn rollers or belts as condition requires.
- Detailed sensor verification.
- Inspect motor and gearbox.
- Verify applicator alignment.
- Review recurring faults.

---

## 20.5 Blender-001

### Spare Parts

- Gearbox bearing.
- Motor contactor.
- Shaft seal kit.
- Load cell.
- Proximity sensor.
- Drive coupling.

### Weekly PM

- Check seals for leakage.
- Inspect agitator or mixing shaft.
- Check abnormal noise and vibration.
- Inspect guards.
- Verify proximity sensors.

### Biweekly PM

- Inspect coupling.
- Inspect motor and gearbox mounts.
- Verify load-cell readings.
- Inspect wiring.
- Check critical fasteners.

### Monthly PM

- Check gearbox oil level.
- Trend vibration.
- Check motor current.
- Inspect bearings.
- Review drive faults.

### Quarterly PM

- Inspect gearbox oil condition.
- Verify load-cell calibration.
- Inspect coupling alignment.
- Check electrical terminations.
- Verify safety interlocks.

### Semiannual PM

- Replace gearbox oil as required.
- Inspect shaft bearings.
- Inspect or rebuild seals.
- Detailed motor inspection.
- Verify alignment.
- Review shared-production dependency risk.

---

## 20.6 Air-Comp-001

### Spare Parts

- Air filter element.
- Oil filter.
- Separator element.
- Drive belt.
- Pressure transducer.
- Motor contactor.

### Weekly PM

- Check oil level.
- Inspect for leaks.
- Check operating pressure.
- Check discharge temperature.
- Listen for abnormal noise.

### Biweekly PM

- Inspect belts.
- Inspect intake filter.
- Drain moisture.
- Inspect cooling system.
- Check operating hours.

### Monthly PM

- Record vibration.
- Check motor current.
- Inspect electrical connections.
- Inspect condensate system.
- Review alarms.

### Quarterly PM

- Replace or inspect air filter.
- Inspect oil filter.
- Inspect belts and tension.
- Check pressure transducer.
- Inspect cooler.

### Semiannual PM

- Change oil and filter if required.
- Replace separator element based on hours or condition.
- Detailed motor inspection.
- Inspect compressor element.
- Verify pressure controls.
- Review reliability trend.

---

# 21. PostgreSQL Design Principles

The database should not assume every asset belongs to only one line.

Shared equipment requires a many-to-many relationship.

Core tables should eventually include:

```text
sites
production_lines
shifts
employees
employee_shift_assignments

assets
asset_line_relationships
asset_production_schedule
asset_criticality

pm_plans
pm_tasks
pm_executions

work_orders
downtime_events
failure_events

sanitation_findings

rca_events
corrective_actions

parts
asset_parts
inventory_transactions

skills
employee_skills

maintenance_costs
capital_projects
kpi_targets
```

---

# 22. Asset-Line Relationship Model

Suggested table concept:

```text
asset_line_relationships

asset_id
line_id
relationship_type
priority
```

Example relationship types:

```text
DEDICATED
SIMULTANEOUS_DEPENDENCY
SCHEDULED_SHARED
```

Example data:

```text
AIR-COMP-001 | LINE-1 | SIMULTANEOUS_DEPENDENCY
AIR-COMP-001 | LINE-2 | SIMULTANEOUS_DEPENDENCY

BLENDER-001  | LINE-1 | SCHEDULED_SHARED
BLENDER-001  | LINE-2 | SCHEDULED_SHARED

FILLER-101   | LINE-1 | DEDICATED
FILLER-201   | LINE-2 | DEDICATED
```

This allows the system to determine production impact from asset relationships.

---

# 23. Shared Asset Scheduling

Blender-001 requires production scheduling data.

Suggested table concept:

```text
asset_production_schedule

asset_id
line_id
scheduled_start
scheduled_end
production_order
```

The system should be able to determine:

- Which line is currently dependent on Blender-001.
- Which line is next.
- Which future production orders are at risk.
- Estimated delay if the blender remains unavailable.

---

# 24. PM Database Structure

PM plans should be stored independently from PM tasks.

## pm_plans

Suggested fields:

```text
id
asset_id
pm_code
frequency_type
frequency_days
title
estimated_minutes
priority
active
```

Frequency examples:

```text
WEEKLY
BIWEEKLY
MONTHLY
QUARTERLY
SEMIANNUAL
```

## pm_tasks

Suggested fields:

```text
id
pm_plan_id
sequence_number
task_description
requires_shutdown
safety_note
```

## pm_executions

Suggested fields:

```text
id
pm_plan_id
scheduled_date
completed_date
status
technician_id
work_order_id
completion_notes
```

---

# 25. Spare Parts Database Structure

## parts

Suggested fields:

```text
id
part_number
description
quantity_on_hand
minimum_quantity
maximum_quantity
unit_cost
critical_spare
lead_time_days
```

## asset_parts

Suggested fields:

```text
id
asset_id
part_id
quantity_required
critical_for_asset
notes
```

This supports shared spare parts between multiple assets.

---

# 26. Work Order Structure

The work order system should support:

- Preventive.
- Corrective.
- Emergency.
- Predictive.
- Sanitation finding.
- Inspection.
- Project.

Suggested fields:

```text
work_order_number
asset_id
work_type
priority
title
description
requested_at
acknowledged_at
work_started_at
work_completed_at
closed_at
status
emergency
planned
failure_code
cause_code
labor_hours
labor_cost
parts_cost
```

---

# 27. Downtime Data

Downtime should be stored separately from work orders.

Suggested fields:

```text
asset_id
work_order_id
downtime_start
downtime_end
planned
reason
production_impact
affected_line
```

This allows multiple production-impact calculations from a single maintenance event.

---

# 28. Failure and RCA Structure

## failure_events

Suggested fields:

```text
asset_id
work_order_id
failure_time
failure_mode
production_stopped
repeat_failure
```

## rca_events

Suggested fields:

```text
work_order_id
problem_statement
root_cause
method
opened_at
completed_at
status
```

## corrective_actions

Suggested fields:

```text
rca_id
action_description
owner
due_date
completed_date
action_type
verified_effective
```

---

# 29. Sanitation Findings Structure

Suggested fields:

```text
finding_number
asset_id
reported_by
reported_at
description
priority
maintenance_required
startup_risk
work_order_id
status
```

Sanitation should be able to trigger a maintenance work order.

---

# 30. Skills and Training Structure

The system should support technician capability tracking.

Example proficiency levels:

1. Awareness
2. Assisted
3. Independent
4. Trainer / Expert

Suggested tables:

```text
skills
employee_skills
```

The system should calculate:

- Critical asset coverage.
- Employees qualified per asset.
- Shift-specific coverage.
- Cross-training percentage.
- Skill gaps.

---

# 31. Grafana Dashboard Strategy

The initial demo should use three dashboards.

---

# 32. Grafana Dashboard 1 - VP Operations Overview

Purpose:

Provide the VP of Operations with a high-level reliability view.

Top KPI cards:

- Plant Uptime.
- PM Compliance.
- Emergency Work Percentage.
- MTTR.
- MTBF.
- Work Order Closure Rate.
- Critical Spare Availability.
- Repeat Failure Reduction.

Additional panels:

- Line 1 uptime.
- Line 2 uptime.
- Unplanned downtime trend.
- Top downtime assets.
- Planned versus reactive maintenance.
- Emergency work trend.
- Critical production risks.
- Shared asset condition.
- Open major RCA actions.

---

# 33. Grafana Dashboard 2 - Maintenance Reliability

Purpose:

Provide drill-down visibility for the Maintenance Manager.

Panels:

- Open work orders.
- Critical work orders.
- Overdue PMs.
- PM compliance.
- MTTR by asset.
- MTBF by asset.
- Repeat failures.
- Failure Pareto.
- Top downtime equipment.
- Downtime by failure mode.
- RCA status.
- Corrective action status.
- Filler-201 repeat failure trend.
- Conveyor-201 repeat failure trend.

Example asset table:

| Asset | Line | Uptime | Open WO | Failures | PM Status |
|---|---|---:|---:|---:|---|
| Mixer-101 | Line 1 | 97.9% | 0 | 1 | Good |
| Conveyor-101 | Line 1 | 97.3% | 1 | 1 | Good |
| Filler-101 | Line 1 | 95.8% | 1 | 2 | Good |
| Labeler-101 | Line 1 | 98.2% | 0 | 0 | Good |
| Mixer-201 | Line 2 | 96.9% | 0 | 1 | Good |
| Conveyor-201 | Line 2 | 92.8% | 2 | 3 | Due |
| Filler-201 | Line 2 | 89.6% | 3 | 4 | Late |
| Labeler-201 | Line 2 | 97.1% | 0 | 1 | Good |
| Blender-001 | Shared | TBD | TBD | TBD | TBD |
| Air-Comp-001 | Utility | TBD | TBD | TBD | TBD |

---

# 34. Grafana Dashboard 3 - Staffing, Sanitation, and Operational Risk

Purpose:

Show maintenance coverage and production support risk.

Panels:

- Current shift.
- Maintenance technician on duty.
- No-maintenance sanitation coverage warning.
- Open sanitation findings.
- Startup risk.
- Planned maintenance during sanitation.
- Reactive versus planned overtime.
- Technician skills coverage.
- Critical equipment cross-training.
- Critical spare availability.
- Shared production equipment risk.
- Utility risk.

---

# 35. KPI Calculation Concepts

## PM Compliance

```text
PMs completed on or before due date
------------------------------------ x 100
PMs scheduled
```

Target:

```text
>= 98%
```

## Emergency Work Percentage

```text
Emergency Work Orders
--------------------- x 100
Total Work Orders
```

Target:

```text
< 30%
```

## MTTR

Average:

```text
work_completed_at - work_started_at
```

for qualifying repair work orders.

## Critical Response Time

Average:

```text
acknowledged_at - requested_at
```

for critical breakdowns.

Target:

```text
<= 15 minutes
```

## Uptime

Conceptually:

```text
Available Production Time - Unplanned Downtime
-----------------------------------------------
Available Production Time
```

## Critical Spare Availability

Conceptually:

```text
Critical parts at or above minimum stock
-----------------------------------------
Total required critical parts
```

---

# 36. Seed Data Scope

The target demo history should contain enough records to create meaningful trends without becoming unnecessarily large.

Proposed scope:

```text
Historical Period:
Approximately 8 months

Assets:
10

PM Plans:
50

PM Tasks:
Approximately 200

Historical PM Executions:
Approximately 300+

Historical Work Orders:
Approximately 200

Downtime Events:
Approximately 80

Failure Events:
Approximately 70

RCA Events:
Approximately 10-15

Sanitation Findings:
Approximately 30-40

Critical / Common Spare Parts:
Approximately 25-40 unique parts

Employees:
Approximately 10
```

Some parts should be shared between multiple assets.

---

# 37. Interview Demo Flow

The interview demo should tell a story rather than simply show dashboards.

## Step 1 - Start with the VP Dashboard

Show:

```text
Plant Uptime: 94.8%
Target: >= 95%
```

Explain that overall plant performance is near target.

## Step 2 - Compare Production Lines

Show:

```text
Line 1: Approximately 97%
Line 2: Approximately 92-94%
```

Explain that the plant-level KPI hides a reliability problem on Line 2.

## Step 3 - Drill into Line 2

Show that Filler-201 is the largest contributor to downtime.

## Step 4 - Review Failure History

Show repeated Filler-201 sensor-related failures.

## Step 5 - Review Work Orders

Show that maintenance repeatedly restored operation by realigning the sensor.

## Step 6 - Show RCA

Demonstrate that the true root cause is the sensor bracket and mounting hardware.

## Step 7 - Show Corrective Actions

- Replace damaged bracket.
- Add locking hardware.
- Inspect similar machines.
- Update weekly PM.
- Add spare bracket.
- Verify future effectiveness.

## Step 8 - Show PM Revision

Demonstrate that maintenance learning changed the preventive maintenance strategy.

## Step 9 - Show Spare Parts

Demonstrate that the sensor and bracket are now tracked as critical spares supporting both fillers.

## Step 10 - Show Predictive Maintenance

Move to Air-Comp-001.

Show increasing vibration while the compressor is still operational.

Explain that both production lines depend on the compressor.

## Step 11 - Show Planned Maintenance Window

Schedule compressor work during the sanitation shift.

Demonstrate planned overtime instead of reactive production interruption.

## Step 12 - Show Shared Blender Risk

Demonstrate how Blender-001 can affect one line immediately and the other line later because it is shared sequentially.

## Step 13 - Return to VP Dashboard

Show how every event feeds the KPI system.

The message should be:

> Production impact creates data. The data identifies where reliability is being lost. Maintenance uses work orders, RCA, PM, predictive maintenance, spare-parts planning, and training to reduce that loss. Grafana then shows Operations whether those changes are actually working.

---

# 38. Demo Talking Point

A concise interview statement:

> What I took from the job description is that you are not simply looking for someone to manage technicians. You are looking for someone to build a maintenance system. I put together this small example to show how I would connect assets, work orders, downtime, PMs, root cause analysis, spare parts, staffing, sanitation, and production dependencies into one measurable reliability program.

---

# 39. Initial Architecture

```text
                   Demo Maintenance Application
                            |
                            v
                       PostgreSQL
                            |
        ---------------------------------------------
        |            |            |                 |
      Assets      Work Orders      PMs          Inventory
        |            |            |                 |
        |         Downtime      Executions       Asset Parts
        |            |
        |         Failures
        |            |
        |           RCA
        |            |
        |      Corrective Actions
        |
        +------ Production Dependencies
        |
        +------ Shared Equipment Scheduling
        |
        +------ Sanitation Findings
        |
        +------ Employee Skills
                            |
                            v
                         Grafana
                            |
          --------------------------------------
          |                 |                  |
     VP Operations      Maintenance       Staffing / Risk
       Dashboard         Dashboard           Dashboard
```

---

# 40. Future Build Phases

## Phase 1 - Database Foundation

- PostgreSQL schema.
- Asset registry.
- Production lines.
- Shared asset relationships.
- Shifts and employees.
- PM plans.
- PM tasks.
- Parts.
- Asset-part relationships.

## Phase 2 - Historical Demo Data

- Seed 8 months of work orders.
- Seed PM executions.
- Seed downtime.
- Seed failure events.
- Seed RCA events.
- Seed sanitation findings.
- Seed parts inventory.
- Seed technician skill levels.

## Phase 3 - KPI Views

Create PostgreSQL views for:

- Plant uptime.
- Line uptime.
- Asset uptime.
- PM compliance.
- Emergency WO percentage.
- MTTR.
- MTBF.
- Critical response time.
- Repeat failures.
- Critical spare availability.
- Work order closure.
- Planned versus reactive work.
- Reactive versus planned overtime.

## Phase 4 - Grafana

Build:

1. VP Operations Dashboard.
2. Maintenance Reliability Dashboard.
3. Staffing / Sanitation / Operational Risk Dashboard.

## Phase 5 - Demo Interaction

Optional small application for:

- Creating work orders.
- Completing PMs.
- Entering sanitation findings.
- Opening RCA.
- Completing corrective actions.
- Adjusting spare-parts inventory.
- Recording predictive readings.

## Phase 6 - Interview Polish

- Seed realistic names and data.
- Create repeatable demo scenarios.
- Add presentation talking points.
- Add backup screenshots.
- Add failure simulation controls if useful.
- Package with Docker for one-command startup.

---

# 41. Current Decisions Locked In

The following design decisions have been agreed upon so far:

- PostgreSQL will store the maintenance data.
- Grafana will provide dashboards.
- One manufacturing facility.
- Two production lines.
- Four dedicated pieces of equipment per line.
- One shared production asset.
- One shared utility asset.
- Ten total assets.
- Two production shifts.
- One sanitation shift.
- One maintenance technician per production shift.
- No normal maintenance technician on sanitation shift.
- Approximately 10 employees.
- Shared utility affects both lines simultaneously.
- Shared production asset is used by both lines sequentially.
- Every asset receives:
  - Weekly PM.
  - Biweekly PM.
  - Monthly PM.
  - Quarterly PM.
  - Semiannual PM.
- Every asset receives a short spare-parts list.
- Filler-201 will be the primary RCA / repeat-failure scenario.
- Conveyor-201 will be a secondary reliability problem.
- Air-Comp-001 will demonstrate predictive maintenance and plant-wide dependency.
- Blender-001 will demonstrate shared-resource production scheduling risk.
- Sanitation findings can generate maintenance work.
- Historical data should show improvement but not perfect performance.
- Grafana should show three primary dashboards.
- The demo should focus on reliability management, not simply CMMS software.

---

# 42. Open Design Items

These items still need to be finalized:

- Final company / plant name for the fictional demo.
- Exact product being manufactured.
- Exact shift times if different from the current example.
- Final employee names.
- Final criticality scoring method.
- Final baseline KPI values.
- Final current KPI values.
- Exact PM estimated durations.
- Exact spare-part quantities and costs.
- Exact production schedule for Blender-001.
- Compressor predictive alarm thresholds.
- Downtime cost per line.
- Production rate per line.
- Budget values.
- Capital project example.
- Final Grafana dashboard layout.
- Whether a web UI will be included in the first interview demo.
- Whether the environment will be packaged with Docker.

---

# 43. Next Recommended Step

Build the PostgreSQL foundation from this document.

The next implementation artifact should define:

1. Complete PostgreSQL schema.
2. All 10 assets.
3. Production-line relationships.
4. Shift assignments.
5. Employee records.
6. 50 PM plans.
7. Approximately 200 PM tasks.
8. Spare-parts master list.
9. Asset-to-part relationships.
10. Initial seed data structure.

Once the database model is stable, the Grafana dashboards can be built directly against real PostgreSQL views rather than mocked values.

---

# 44. Milestone 1 Implementation (2026-08-27)

## Implemented Architecture

The discovered repository was a minimal Python/PyCharm project with no application framework, PostgreSQL integration, SQLAlchemy, Alembic, tests, Docker Compose, or Grafana provisioning. PostgreSQL 17.5 was already running locally and was reused. Docker Desktop was not running and no additional PostgreSQL or Grafana container was created.

The PostgreSQL server contains databases belonging to unrelated applications. This demo therefore uses a dedicated `atx_demo_dashboard` database with its `public` schema. Existing databases, schemas, and objects are not modified. This is the dedicated-database model described in the design, with server-level isolation from other applications.

The database foundation uses ordered SQL migrations because the project was SQL-only. Introducing SQLAlchemy and Alembic solely for this milestone would add an unused application abstraction. PowerShell wrappers read the existing project-root `.env`, pass credentials to PostgreSQL through the process environment, and never print passwords or credential-bearing URLs.

## Environment Configuration

Required existing variables:

```text
POSTGRES_USER
POSTGRES_PASSWORD
```

Supported optional variables and defaults:

```text
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=atx_demo_dashboard
POSTGRES_SCHEMA=public
```

`.env.example` contains placeholders only. `.gitignore` excludes `.env`.

## Initialization, Seed, and Validation

Run from the project root:

```powershell
.\scripts\validate-environment.ps1
.\scripts\initialize-database.ps1
.\scripts\seed-database.ps1
.\scripts\validate-database.ps1
```

To intentionally rebuild only the project-owned database:

```powershell
.\scripts\rebuild-database.ps1 -ConfirmRebuild
```

The rebuild command has an exact database-name guard and refuses to drop another database.

## Implemented Database Objects

The foundation implements all required relational areas: sites, lines, shifts, employees and assignments; assets, many-to-many line relationships, shared production schedules and criticality; revision-aware PM plans, tasks and executions; work orders, downtime, affected lines, failures, RCA and corrective actions; sanitation findings; shared spare-parts inventory and transactions; skills; maintenance costs; capital projects; and KPI targets.

PM revision history is modeled with `pm_plan_revisions`. Tasks identify their plan revision, and executions identify the revision performed. A future Filler-201 RCA can close revision 1 and add revision 2 containing bracket-security, locking-hardware, fatigue/damage, and post-inspection alignment checks without deleting the original content.

Asset criticality uses eight understandable 1-to-5 risk factors and a business classification. A higher redundancy value represents higher risk due to lack of redundancy. Air-Comp-001 is `PLANT_CRITICAL`; Blender-001 and both fillers are class `A`.

Inventory retains an operational opening-balance transaction in addition to the current quantity on the part master. Future receipts, issues, returns, and adjustments are constrained by transaction type and sign.

## Grafana Datasource and Views

No Grafana service was required for Milestone 1. A future datasource should use the same environment-driven PostgreSQL connection and query the `public.v_*` views. Passwords must be supplied through Grafana environment or secret handling, not provisioning source or dashboard JSON.

Implemented views:

- `v_plant_uptime`
- `v_line_uptime`
- `v_asset_uptime`
- `v_pm_compliance`
- `v_emergency_work_percentage`
- `v_mttr`
- `v_mtbf`
- `v_critical_response_time`
- `v_repeat_failures`
- `v_work_order_closure_rate`
- `v_critical_spare_availability`
- `v_downtime_by_asset`
- `v_downtime_by_failure_mode`
- `v_planned_vs_reactive_work`
- `v_planned_vs_reactive_overtime`
- `v_open_critical_work_orders`
- `v_overdue_pm`
- `v_open_rca_actions`
- `v_sanitation_maintenance_risk`
- `v_shared_asset_risk`

Views calculate from operational records. Empty historical tables produce empty or null KPI results rather than fabricated percentages. Historical event generation and dashboard presentation remain later milestones.

## Milestone Status

Milestone 1 database foundation is implemented and validated. The master seed contains 10 assets, exactly 50 active PM plans, 260 documented PM tasks, shared asset dependencies, three shifts and ten employees, asset criticality, 30 shared/common spare parts, 60 asset-part relationships, eight skills, and the target KPI definitions.

Milestone 2 remains the eight-month operational history: PM executions, work orders, downtime, failure/RCA history, sanitation findings, inventory usage, condition readings, and trend-producing costs. Dashboard construction and interaction remain later phases.

---

# 45. Milestone 2 Implementation (2026-08-27)

## Historical Dataset Strategy

Milestone 2 uses deterministic SQL with a fixed demonstration period of January 1 through August 26, 2026. No generated record depends on the execution date or an unseeded random function. The guarded rebuild produces the same identifiers, event dates, relationships, counts, and KPI results.

The historical seed contains 201 work orders, 640 PM executions, 80 downtime events, 70 failure events, 12 RCAs, 39 corrective actions, 37 sanitation findings, 41 inventory transactions, 331 maintenance cost records, and 170 normalized condition measurements. It also creates daily sequential Blender schedules and one approved $18,500 Conveyor-201 reliability project with $36,000 estimated annual savings.

Apply history to an existing Milestone 1 database:

```powershell
.\scripts\seed-history.ps1
.\scripts\validate-milestone2.ps1
```

Use the complete guarded rebuild for a clean demonstration database:

```powershell
.\scripts\validate-environment.ps1
.\scripts\rebuild-database.ps1 -ConfirmRebuild
```

## Schema and View Additions

`condition_measurements` is the only new table. It stores normalized asset, measurement type, timestamp, numeric value, unit, warning/alarm thresholds, threshold direction, source, and notes. Its composite index supports asset/type time-series queries.

Twenty-two purpose-specific Grafana views were added for monthly/weekly KPI trends, asset reliability, backlog, PM revision history, the Filler-201 RCA story, Blender shared risk, compressor condition, staffing coverage, technician skills, and operational risks. Business calculations remain in PostgreSQL rather than dashboard expressions.

## Verified Improvement Story

Actual database-derived baseline to August results are:

| KPI | Baseline | August 2026 |
|---|---:|---:|
| Plant uptime | 90.78% | 95.16% |
| PM compliance | 74.44% | 95.71% |
| Emergency work | 48.00% | 26.92% |
| MTTR | 81.82 minutes | 69.75 minutes |
| MTBF | 41.33 hours | 82.67 hours |
| Critical spare availability | 84.00% | 96.00% |
| Repeat failures | 11 | 5 |
| Work-order closure | 80.00% | 92.31% |
| Reactive overtime | $950 | $300 |

August line uptime is 97.61% for Line 1 and 92.71% for Line 2. The organization is visibly improving while PM compliance, spare availability, and closure rate remain short of their targets.

## Reliability Scenarios

Filler-201 has 26 repeat sensor/bracket failures: 20 before the June RCA and 6 afterward. The RCA identifies vibration, loose hardware, the weak mounting arrangement, inadequate locking, and incomplete PM language. Six Filler-specific actions cover permanent repair, locking hardware, equivalent-equipment inspection, PM revision, spare verification, and recurrence monitoring. Weekly PM revision 1 remains historical; revision 2 adds explicit bracket-security, locking-hardware, fatigue/damage, and alignment tasks.

Conveyor-201 has 20 repeat belt/roller/alignment failures and 10,926 minutes of accumulated downtime, keeping it visible in failure and downtime Pareto panels.

The April 11 Blender event starts at 08:15, affects Line 1 immediately, has a 09:45 estimated return, identifies the Line 2 09:00 schedule as future risk, and records a projected 45-minute Line 2 delay.

Air-Comp-001 remains operational with zero unplanned downtime. Monthly average vibration rises from 1.63 to 3.13 mm/s. A predictive work order schedules the intervention from 22:30 to 01:00 during sanitation, demonstrating planned overtime in place of emergency production interruption.

## Grafana Configuration

Grafana 13.0.2 was discovered as an installed Windows service/application. The project starts a separate loopback-only instance on port 3001 using the installed binary, with runtime data isolated under ignored `.grafana` storage. It does not create a PostgreSQL container or duplicate database.

Datasource provisioning uses `ATX Maintenance PostgreSQL` (`atx-postgres`) and reads PostgreSQL credentials from the startup process environment. No credential is stored in provisioning or dashboard JSON.

Start and validate:

```powershell
.\scripts\start-grafana.ps1
.\scripts\validate-grafana.ps1
```

Stop:

```powershell
.\scripts\stop-grafana.ps1
```

Dashboard URLs:

- `http://127.0.0.1:3001/d/atx-vp-operations/vp-operations-overview`
- `http://127.0.0.1:3001/d/atx-maintenance-reliability/maintenance-reliability`
- `http://127.0.0.1:3001/d/atx-operational-risk/staffing-sanitation-and-operational-risk`

The project instance permits anonymous Viewer access only on `127.0.0.1`, avoiding a stored demo login while preventing remote access. An administrator account is also enabled:
- **Username:** `admin`
- **Password:** `admin`
- **Login URL:** `http://127.0.0.1:3001/login`

## Dashboard Purpose & Structure

### 1. VP Operations Overview (`atx-vp-operations`)
- **Executive KPI Scorecard**: 8 Stat cards (Plant Uptime 95.16%, PM Compliance 95.71%, Emergency Work 26.92%, MTTR 69.75 min, MTBF 82.67 hrs, WO Closure 92.31%, Critical Spares 96.00%, Repeat Failures 5).
- **Production Performance**: Monthly Plant Uptime trend with 95% target reference line, and Line 1 (97.61%) vs Line 2 (92.71%) comparative uptime series.
- **Where Are We Losing Production?**: Horizontal Bar Charts for Top Downtime Assets (Filler-201, Conveyor-201) and Top Failure Modes, plus monthly Unplanned Downtime trend.
- **Reactive vs Controlled Maintenance**: Stacked monthly work orders (Planned vs Reactive) and Emergency Work Order % trend with 30% target reference line.
- **Current Operations Risks & Actions**: Live tables for Active Operational Risks and RCA Corrective Actions.
- **Executive AI Maintenance Assistant**: Grounded LLM interaction guide and key interview talking points.

### 2. Maintenance Reliability (`atx-maintenance-reliability`)
- **Variables**: Dynamic `line` (All, Line 1, Line 2) and cascading `asset` filters.
- **Maintenance Status Scorecard**: Open Work Orders, Critical Work Orders, Overdue PMs, PM Compliance, Repeat Failures, and Open RCA Actions.
- **Reliability Metrics by Asset**: Horizontal Bar Charts for MTTR (worst-to-best), MTBF, Downtime Pareto, and Failure Event counts.
- **Preventive Maintenance Performance**: PM Compliance monthly trend with 98% target line, PM Completion status breakdown, and detailed Overdue PM execution table.
- **Failure Analysis & Repeat Issues**: Failure Mode Pareto, Downtime by Failure Mode, and repeat failure assets with recurrence indicators.
- **Filler-201 Primary Case Study**: Chronological failure timeline, monthly downtime trend, RCA details (vibration/bracket fatigue), corrective actions verification, and PM revision before/after comparison.
- **Conveyor-201 Secondary Case Study**: Repeat tracking failure history, monthly downtime trend, and business case context for capital drive upgrade ($18.5k cost, <1 yr payback).
- **Plant-Wide Asset Reliability Master Summary**: Full-width table across all 10 assets covering line scope, criticality, uptime, failures, repeats, downtime, open WOs, and late PMs.

### 3. Staffing, Sanitation & Operational Risk (`atx-operational-risk`)
- **Staffing Coverage Model**: Shift A (1 Tech), Shift B (1 Tech), and Sanitation Shift (0 Techs — highlighted coverage gap).
- **Sanitation Findings & Startup Risk Workflow**: Open findings, maintenance-required findings, startup risks, monthly trend, and active finding triage table.
- **Overtime Economics**: Monthly stacked bar chart of Planned Overtime ($1,450 in Aug) vs Reactive Overtime ($300 in Aug, reduced from $950 baseline), plus reactive overtime trend.
- **Technician Capability & Skills Matrix**: Full matrix of technician proficiency across mechanical, electrical, PLC, pneumatics, and critical machine centers, plus critical skill coverage analysis.
- **Critical Spare Parts Management**: Critical spare availability stat (96.00%) and critical spare inventory & shortage table.
- **Air-Comp-001 Predictive Condition Monitoring**: High-frequency vibration trend showing progressive degradation (1.63 → 3.13 mm/s) against 2.5 mm/s warning and 4.0 mm/s alarm thresholds, temperature/current/pressure series, and dual-line plant dependency summary.
- **Blender-001 Shared Asset Production Risk**: Sequential production schedule (Line 1 vs Line 2) and shared-asset failure impact (immediate Line 1 downtime + projected 45 min Line 2 startup delay).

## Grafana Validation

`validate-grafana.ps1` checks the Grafana health API, PostgreSQL datasource health, all three provisioned dashboard UIDs, every panel SQL target, dashboard variables, and explicit Filler-201 asset-filter drill-downs. The validated run executed 73 panel/variable queries: 73 passed, 0 failed, with 73 returned data frames.

## Grafana LLM Integration Architecture

The Grafana LLM application plugin (`grafana-llm-app` v1.0.8) connects Grafana to OpenAI models (`gpt-4o-mini` as BASE and `gpt-4o` as LARGE). The integration adheres strictly to data security and operational reliability principles:

1. **Security & Key Management**: Credentials (`OPENAI_API_KEY`) are managed securely via environment variables and plugin provisioning. No keys are hardcoded in dashboard JSON or committed to source control.
2. **PostgreSQL as Single Source of Truth**: The LLM is used strictly for contextual interpretation, executive narrative summaries, and cross-metric correlation—never for KPI calculation or arbitrary SQL execution.
3. **Controlled Context Grounding**: The AI consumes structured data feeds from curated PostgreSQL views (`v_plant_uptime`, `v_line_uptime`, `v_downtime_by_asset`, `v_repeat_failures`, `v_open_rca_actions`, `v_shared_asset_risk`, `v_pm_compliance`, `v_critical_spare_availability`, `v_condition_measurements`, and `v_sanitation_maintenance_risk`).
4. **Model Tiering**:
   - **BASE Model (`gpt-4o-mini`)**: Quick panel explanations, short KPI observations, operational definitions.
   - **LARGE Model (`gpt-4o`)**: Deep RCA reasoning, cross-dashboard synthesis, VP Operations weekly focus briefings.
5. **AI Safety Rules**:
   - Base all statements strictly on actual database records.
   - Distinguish facts from inferences.
   - Zero hallucination of work orders, downtime events, or KPI values.
   - Strictly read-only; no database write permissions or unsafe maintenance instructions.

## AI Maintenance Summary Validation

The AI integration is validated using `.\scripts\test-ai-summary.ps1` across five standard operational interview inquiries:

1. **What is keeping plant uptime below target?** (BASE)
   - Accurately cites plant uptime (91.31% overall / 95.16% August), Line 2 underperformance (85.95%), and top downtime drivers (Filler-201 at 12,618 min and Conveyor-201 at 10,926 min).
2. **Why is Line 2 worse than Line 1?** (BASE)
   - Explains the disparity: Line 2 experienced 31,706 minutes of unplanned downtime vs. Line 1's 7,512 minutes, driven by packaging and conveyor repeat issues.
3. **What changed after the Filler-201 RCA?** (LARGE)
   - Identifies machine vibration and loose mounting hardware, cites completed corrective actions (bracket replacement, locking hardware, spare verification), PM revision 2 additions (bracket security, locking fasteners, fatigue inspection), and confirmed reduction in failure frequency.
4. **Why is Air-Comp-001 a predictive maintenance concern?** (BASE)
   - Explains that Air-Comp-001 has a `SIMULTANEOUS_DEPENDENCY` on both Line 1 and Line 2, highlighting rising vibration trends (1.63 mm/s to 3.13 mm/s) that require planned intervention during sanitation before tripping both production lines.
5. **What should Operations focus on this week?** (LARGE)
   - Prioritizes high-priority sanitation startup risk on Conveyor-201 belt edge, Conveyor-201 repeat tracking monitoring, maintaining 95.7%+ PM compliance, critical spare replenishment, and Blender-001 shared scheduling coordination.

## Interview Walkthrough

1. Open VP Operations Overview and explain that uptime has reached 95.16%, while PM, spares, and closure remain improvement opportunities.
2. Compare Line 1 at 97.61% with Line 2 at 92.71%.
3. Open Maintenance Reliability and use Filler-201 to show repeated symptom repairs, the RCA, corrective actions, PM revision, and reduced recurrence.
4. Review Conveyor-201 in downtime and failure Pareto as the next reliability opportunity and capital case.
5. Open Staffing, Sanitation & Operational Risk and point out that sanitation has no normal maintenance technician.
6. Show Air-Comp-001 condition degradation, plant-wide dependency, and the planned sanitation-window intervention.
7. Show the Blender event's immediate Line 1 impact and future Line 2 schedule risk.
8. Highlight the AI Maintenance Summary in Grafana providing grounded, real-time executive summaries directly from PostgreSQL views.
9. Return to the VP dashboard to connect operational records to measured improvement.

---

## Milestone 2.5 — Production, Lot Scheduling, Employee Scheduling, and OEE Foundation

Milestone 2.5 establishes the production, lot scheduling, employee scheduling, and Overall Equipment Effectiveness (OEE) data architecture for the demonstration plant. All metrics are calculated deterministically in PostgreSQL views without custom application middleware or hard-coded front-end values.

### 1. Product Master (`products`)
A normalized SKU catalog representing 5 fictional commercial sauce products manufactured across the two lines:
- `ATX-1001` — **Classic Sauce**: Signature mild tomato & herb sauce (500 gal default batch size, 12 units/case).
- `ATX-1002` — **Spicy Sauce**: Habanero and cayenne infused sauce (500 gal default batch size, 12 units/case).
- `ATX-1003` — **Garlic Sauce**: Roasted garlic savory sauce (500 gal default batch size, 12 units/case).
- `ATX-2001` — **BBQ Blend**: Smoky chipotle barbecue sauce (600 gal default batch size, 12 units/case).
- `ATX-2002` — **Sweet Heat**: Honey chili glazed finishing sauce (500 gal default batch size, 12 units/case).

### 2. Product-Line Performance Standards (`product_line_standards`)
Defines line-specific ideal run speeds, expected yields, and changeover standards for each SKU:
- **Line 1 Standards** (Higher-speed packaging line):
  - Classic Sauce: 140.00 UPM, 99.0% yield, 25 min changeover
  - Spicy Sauce: 120.00 UPM, 98.5% yield, 35 min changeover
  - Garlic Sauce: 130.00 UPM, 98.8% yield, 30 min changeover
  - BBQ Blend: 125.00 UPM, 98.5% yield, 30 min changeover
  - Sweet Heat: 135.00 UPM, 98.7% yield, 30 min changeover
- **Line 2 Standards** (Flexible packaging line):
  - Classic Sauce: 120.00 UPM, 98.5% yield, 30 min changeover
  - Spicy Sauce: 105.00 UPM, 98.0% yield, 40 min changeover
  - Garlic Sauce: 115.00 UPM, 98.3% yield, 35 min changeover
  - BBQ Blend: 110.00 UPM, 98.2% yield, 35 min changeover
  - Sweet Heat: 115.00 UPM, 98.4% yield, 35 min changeover

### 3. Production Calendar (`production_calendar`)
Defines the planned operating time (OEE Availability denominator) for each production shift and line:
- **Shift Duration**: 480 minutes (8 hours) per shift.
- **Planned Breaks**: 30 minutes.
- **Planned Changeover Allowance**: 30 minutes.
- **Planned Production Time**: 420 minutes per shift per line (840 minutes/day per line).
- **Calendar Period**: 172 operating days (Jan 1 – Aug 28, 2026), generating 688 planned calendar shifts.

### 4. Production Lots & Lifecycle (`production_lots` & `production_lot_events`)
Tracks lot execution from initial creation to completion:
- **Lot Number Format**: Unique identifier encoding date, line, and daily sequence (e.g., `ATX-20260827-L1-002`).
- **Statuses Supported**: `PLANNED`, `READY`, `RUNNING`, `PAUSED`, `COMPLETE`, `CANCELLED`.
- **Event History**: Granular timestamps for `CREATED`, `READY`, `STARTED`, `PAUSED`, `RESUMED`, `COMPLETED`, and `CANCELLED`.
- **Current Real-Time Demo Snapshot** (August 27, 2026, 19:13:00 CDT):
  - Line 1: `ATX-20260827-L1-002` (Classic Sauce) is **RUNNING** with 69.5% progress and 99.00% yield.
  - Line 2: `ATX-20260827-L2-002` (Garlic Sauce) is **RUNNING** with 69.5% progress and 99.00% yield.
  - Next in queue: `ATX-20260828-L1-001` (Spicy Sauce) and `ATX-20260828-L2-001` (BBQ Blend) in **READY** state for Shift A tomorrow.

### 5. Employee Scheduling & Staffing Model (`employee_schedules`)
Maintains employee assignments across all 8 months (1,720 shift records), strictly adhering to the plant staffing model:
- **Shift A (06:00 – 14:00)**: 1 Production Lead (E005), 1 Line 1 Operator (E003), 1 Line 2 Operator (E004), 1 Maintenance Tech (E001).
- **Shift B (14:00 – 22:00)**: 1 Production Lead (E008), 1 Line 1 Operator (E006), 1 Line 2 Operator (E007), 1 Maintenance Tech (E002).
- **Sanitation Shift (22:00 – 06:00)**: 1 Sanitation Lead (E009), 1 Sanitation Tech (E010), **0 regular maintenance technicians**.

### 6. Shared Blender Lot Scheduling (`production_lot_assets`)
Models shared production equipment arbitration on Blender-001:
- Blender-001 is scheduled across both lines with non-overlapping sequential windows (e.g. Line 1: 06:00–09:30 / 14:00–17:30; Line 2: 09:30–13:00 / 17:30–21:00).
- Prevents cross-line schedule collisions while tracking real-time line ownership and downstream starvation risks.

### 7. OEE Methodology & Mathematical Formulation
Standard industry OEE is calculated without artificial clamps:
$$\text{OEE} = \text{Availability} \times \text{Performance} \times \text{Quality}$$

1. **Availability**:
   $$\text{Availability} = \frac{\text{Run Time}}{\text{Planned Production Time}}$$
2. **Performance**:
   $$\text{Performance} = \frac{\text{Total Count}}{\text{Run Time} \times \text{Ideal Rate}}$$
3. **Quality**:
   $$\text{Quality} = \frac{\text{Good Count}}{\text{Total Count}}$$

#### Batch Assets vs Continuous Packaging Lines
- **Batch Assets** (Mixer-101, Mixer-201, Blender-001): Run on batch-cycle feed rates (210 min batch window for a 420 min packaging run), with performance evaluated against batch cycle completion rates.
- **Why Air-Comp-001 is Excluded from OEE**: Air-Comp-001 is a utility asset that does not produce piece-rate or batch units. It is evaluated via Availability, MTBF, MTTR, and high-frequency condition monitoring (vibration, temperature, current, pressure).
- **Line-Level OEE Rule**: Line OEE is calculated directly at the line system level from line planned minutes, line actual runtime, line-weighted ideal rates, and line unit counts. **Line OEE is never computed as an average of asset OEE.**

### 8. Historical OEE Trends & Scenarios

| Level / Period | Availability | Performance | Quality | OEE | Key Observation |
|---|---|---|---|---|---|
| **Line 1 (January 2026)** | 95.84% | 94.06% | 98.90% | **89.15%** | Benchmark line operating near target |
| **Line 1 (August 2026)** | 95.67% | 94.06% | 98.89% | **88.99%** | Stable high availability and throughput |
| **Line 2 (January 2026)** | 82.14% | 94.06% | 97.92% | **75.65%** | Degraded availability due to Filler-201 & Conveyor-201 |
| **Line 2 (August 2026)** | 93.05% | 94.06% | 98.69% | **86.38%** | **+10.73% OEE improvement** post-RCA |
| **Filler-201 (Pre-RCA Jan–May)** | 83.81% | 92.26% | 97.91% | **75.71%** | 10,448 min downtime, 20 repeat sensor faults |
| **Filler-201 (Post-RCA Jun–Aug)** | 95.62% | 91.45% | 98.69% | **86.31%** | **+10.60% OEE gain**, downtime reduced to 2,170 min |

### 9. Milestone 2.5 PostgreSQL Views
1. `v_current_production_lots`: Real-time lot status, progress percentage, and yield for running lots.
2. `v_upcoming_production_lots`: Next scheduled production lots by line and start time.
3. `v_completed_production_lots`: Historical completed lots with planned vs actual times and counts.
4. `v_production_schedule_adherence`: On-time start and completion percentages based on 10-minute tolerance.
5. `v_employee_schedule_current`: Active roster and role assignments for the current production shift.
6. `v_employee_schedule_daily`: Full daily employee roster by date, shift, role, and line.
7. `v_shift_staffing_coverage`: Shift staffing matrix validating the 1/1/0 maintenance coverage rule.
8. `v_asset_oee_daily`: Daily Availability, Performance, Quality, and OEE per in-scope asset.
9. `v_asset_oee_weekly`: Weekly aggregated asset OEE metrics.
10. `v_asset_oee_monthly`: Monthly aggregated asset OEE trends.
11. `v_line_oee_daily`: Daily Line 1 and Line 2 OEE computed at the production line system level.
12. `v_line_oee_weekly`: Weekly Line 1 and Line 2 OEE.
13. `v_line_oee_monthly`: Monthly Line 1 and Line 2 OEE trends.
14. `v_asset_oee_components`: Summary of overall A/P/Q/OEE components per asset.
15. `v_line_oee_components`: Summary of overall A/P/Q/OEE components per production line.
16. `v_oee_loss_by_category`: Loss breakdown across Unplanned Maintenance, Planned Maintenance, Changeover, and Breaks.
17. `v_filler201_oee_before_after_rca`: Pre vs Post RCA comparison of Filler-201 OEE, availability, and repeat failures.

---

## Milestone 3 — Grafana Production & OEE Performance & Executive Navigation

Milestone 3 delivers the dedicated 4th Grafana interview dashboard (**Production & OEE Performance**) and adds a compact OEE summary row to the **VP Operations Overview** dashboard. It establishes unified bidirectional navigation across all 4 operational dashboards.

### 1. Dashboard Architecture & URLs

The interview demonstration is organized into four interconnected dashboards:

| Dashboard | UID | URL | Primary Purpose |
|---|---|---|---|
| **VP Operations Overview** | `atx-vp-operations` | `http://127.0.0.1:3001/d/atx-vp-operations/vp-operations-overview` | 30-second executive scorecard, uptime, reliability trends, compact OEE summary |
| **Maintenance Reliability** | `atx-maintenance-reliability` | `http://127.0.0.1:3001/d/atx-maintenance-reliability/maintenance-reliability` | Maintenance deep-dive: WOs, PMs, MTTR/MTBF, failure Pareto, Filler-201 / Conveyor-201 RCAs |
| **Staffing, Sanitation & Operational Risk** | `atx-operational-risk` | `http://127.0.0.1:3001/d/atx-operational-risk/staffing-sanitation-and-operational-risk` | Staffing 1/1/0 model, sanitation startup risks, overtime economics, technician skills, CBM & shared asset risk |
| **Production & OEE Performance** | `atx-production-oee` | `http://127.0.0.1:3001/d/atx-production-oee/production-and-oee-performance` | Active lot execution, line OEE & A/P/Q components, asset OEE ranking, loss Pareto, schedule adherence |

### 2. Dedicated Dashboard: Production & OEE Performance (`atx-production-oee`)

The dashboard is structured into 7 logical rows:

1. **Current Production Status & Shift Staffing** (`Row ID 100`):
   - **Line 1 Active Lot Status (Running)**: Stat panel showing Lot `ATX-20260827-L1-002` (Classic Sauce), 69.5% progress, 99.00% yield.
   - **Line 2 Active Lot Status (Running)**: Stat panel showing Lot `ATX-20260827-L2-002` (Garlic Sauce), 69.5% progress, 99.00% yield.
   - **Current Staffing Roster (Shift B — 1/1/0 Model)**: Active table showing 1 Production Lead (E008), 1 Line 1 Operator (E006), 1 Line 2 Operator (E007), and 1 Maintenance Tech (E002).
   - **Schedule Adherence (Current Month)**: Stat panel showing 100.0% on-time start compliance under the 10-minute tolerance threshold.
2. **Line OEE Scorecard & Components** (`Row ID 101`):
   - **Line 1 OEE (Target ≥85%)**: Stat panel displaying current August OEE of **88.99%** (Green threshold).
   - **Line 1 A / P / Q Components**: Availability (95.67%), Performance (94.06%), Quality (98.89%).
   - **Line 2 OEE (Target ≥85%)**: Stat panel displaying current August OEE of **86.38%** (Green threshold).
   - **Line 2 A / P / Q Components**: Availability (93.05%), Performance (94.06%), Quality (98.69%).
   - **Line 1 vs Line 2 OEE Monthly Trend**: 8-month timeseries visually highlighting Line 2 OEE recovery from 75.65% in Jan to 86.38% in Aug.
3. **Equipment OEE Ranking & Loss Breakdown** (`Row ID 102`):
   - **Equipment OEE Ranking (Worst-to-Best)**: Table ranking all 9 production assets by overall OEE with color-background highlighting. Utility asset Air-Comp-001 is explicitly excluded.
   - **OEE Availability Loss Categories (August 2026)**: Horizontal barchart showing downtime loss distribution (Unplanned Maintenance 2,170 min on Line 2, Changeovers 1,200 min, Breaks 1,200 min).
4. **Filler-201 Case Study: RCA Impact on OEE** (`Row ID 103`):
   - **Filler-201 Pre vs Post RCA Transformation**: Side-by-side table displaying Pre-RCA (75.71% OEE, 83.81% Availability, 10,448 min downtime, 20 repeat failures) vs Post-RCA (86.31% OEE, 95.62% Availability, 2,170 min downtime, 6 failures).
   - **Filler-201 Monthly OEE & Availability Recovery Trend**: Timeseries showing direct correlation between the June 1 PM Rev 2 update and availability restoration.
5. **Production Scheduling & Performance Standards** (`Row ID 104`):
   - **Upcoming Production Lots Schedule**: Table of next planned lots in the production schedule with target sequence, SKU, and scheduled start times.
   - **Product-Line Speed & Changeover Standards**: Benchmark table displaying ideal run rates (105–140 UPM) and expected yields (98.0–99.0%) across all 5 SKUs.
6. **Shared Assets & Plant Utilities Risk** (`Row ID 105`):
   - **Blender-001 Shared Production Schedule & Conflict Risk**: Table showing sequential production allocation between Line 1 and Line 2.
   - **Air-Comp-001 Utility Vibration Trend**: Timeseries showing progressive bearing degradation (1.63 → 3.13 mm/s) with 2.8 mm/s warning and 4.5 mm/s alarm thresholds, demonstrating predictive CBM intervention without assigning a piece-rate OEE.
7. **Executive AI Production & OEE Assistant** (`Row ID 106`):
   - Text panel detailing how the Grafana LLM integration grounds executive summaries on live PostgreSQL production and OEE views.

### 3. VP Operations Overview Compact OEE Row

A compact **Production & OEE Summary** row (`Row ID 106`) was integrated directly into `vp-operations-overview.json` at position `y: 5`, preserving the 30-second readability of the executive dashboard:
- **Line 1 OEE**: 88.99% (Target ≥85%)
- **Line 2 OEE**: 86.38% (Target ≥85%)
- **Line 1 Current Running Lot**: `ATX-20260827-L1-002 (Classic Sauce)` — Progress: 69.5%, Yield: 99.00%
- **Line 2 Current Running Lot**: `ATX-20260827-L2-002 (Garlic Sauce)` — Progress: 69.5%, Yield: 99.00%
- **Schedule Adherence (On-Time)**: 100.0%
- **Shift Staffing (1/1/0 Model)**: `4 On Duty (1 Maint Tech)`

### 4. Operational Thresholds & Visual Styling

- **OEE & Availability**:
  - `Green (Healthy / Target Met)`: $\ge 85.0\%$
  - `Yellow / Amber (Attention Required)`: $75.0\% \text{ to } < 85.0\%$
  - `Red (Unacceptable / Action Required)`: $< 75.0\%$
- **Quality / Yield**:
  - `Green`: $\ge 98.0\%$
  - `Yellow`: $95.0\% \text{ to } < 98.0\%$
  - `Red`: $< 95.0\%$
- **Vibration (Air-Comp-001)**:
  - `Normal`: $< 2.80\text{ mm/s}$
  - `Warning`: $2.80\text{ to } < 4.50\text{ mm/s}$
  - `Alarm`: $\ge 4.50\text{ mm/s}$

### 5. Automated Validation Results

Validation script `.\scripts\validate-grafana.ps1` verifies datasource connectivity, provisioning of all 4 dashboard UIDs, query execution across all panel targets and dynamic variables, and asset drill-downs:
- **Total Dashboards Provisioned**: 4/4 loaded
- **Total Panel & Variable Queries Tested**: 100 queries
- **Passed Queries**: 100
- **Failed Queries**: 0
- **Data Frames Returned**: 100

### 6. Four-Dashboard Interview Walkthrough Flow

1. **Executive Opening (VP Operations Overview)**:
   - Walk through the top Scorecard: Plant Uptime achieved **95.16%** in August, PM Compliance reached **95.71%**, MTTR improved from 81.82 to **69.75 min**, and Repeat Failures dropped from 11/mo to **5/mo**.
   - Review the new **Production & OEE Summary Row**: Point out Line 1 OEE (**88.99%**) vs Line 2 OEE (**86.38%**), show running lots on both lines (`ATX-20260827-L1-002` and `ATX-20260827-L2-002`), 100% on-time start adherence, and Shift B staffing (4 on duty with 1 maintenance technician).
   - Show Line 1 (97.61%) vs Line 2 (92.71%) uptime trend to establish Line 2 as the primary reliability opportunity.
2. **Production & OEE Deep-Dive (Production & OEE Performance)**:
   - Click the top navigation link to **Production & OEE Performance**.
   - Show the A/P/Q component breakdown: Line 2 underperforms Line 1 due to **Availability (93.05% vs 95.67%)**, while Performance (94.06%) and Quality (98.69%) remain strong on both lines.
   - Review the **Equipment OEE Ranking Table**: Identify `Filler-201` (79.65% overall) and `Conveyor-201` (79.65% overall) as the primary culprits pulling down Line 2 OEE.
   - Show the **OEE Availability Loss Categories**: Explain that unplanned maintenance is the largest loss driver on Line 2 (47.48% of losses).
   - Walk through the **Filler-201 Case Study**: Demonstrate the ROI of reliability engineering—OEE jumped from **75.71% to 86.31%**, Availability improved from **83.81% to 95.62%**, and downtime dropped by 8,278 minutes after PM Rev 2 added bracket security checks.
3. **Maintenance Deep-Dive (Maintenance Reliability)**:
   - Click to **Maintenance Reliability**.
   - Show the root cause analysis for Filler-201 bracket fatigue (`RCA-2026-008`), corrective action close-out, and the before/after PM revision timeline.
   - Show Conveyor-201 belt tracking issues in the Pareto chart as the next capital improvement project ($18.5k cost, <1 yr payback).
4. **Operations Risk, Staffing & Utilities (Staffing, Sanitation & Operational Risk)**:
   - Click to **Staffing, Sanitation & Operational Risk**.
   - Emphasize the **1/1/0 staffing model**: Production shifts have 1 technician on duty, but Sanitation Shift has 0 regular technicians.
   - Review the **Air-Comp-001 predictive CBM strategy**: Explain that utility assets do not have piece-rate OEE; instead, vibration monitoring detected bearing degradation (1.63 → 3.13 mm/s), enabling a planned intervention during the sanitation window that avoided a plant-wide shutdown of both lines.
   - Review **Blender-001 shared asset scheduling**: Explain how sequential batch scheduling between Line 1 and Line 2 prevents cross-line downtime cascades.
5. **Executive Summary & AI Decision Support**:
   - Demonstrate the AI Executive Briefing in Grafana (tested via `.\scripts\test-ai-summary.ps1`) answering complex reliability, OEE, active lot, and staffing questions grounded strictly in PostgreSQL views.
   - Conclude back on the VP Operations Overview dashboard.
