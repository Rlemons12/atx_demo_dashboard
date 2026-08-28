BEGIN;

INSERT INTO sites (site_code, name) VALUES ('ATX', 'ATX Foods Demonstration Plant');

INSERT INTO production_lines (site_id, line_code, name)
SELECT site_id, v.line_code, v.name FROM sites CROSS JOIN (VALUES
    ('LINE-1', 'Line 1'), ('LINE-2', 'Line 2')
) AS v(line_code, name) WHERE site_code = 'ATX';

INSERT INTO shifts (site_id, shift_code, name, function, start_time, end_time)
SELECT site_id, v.* FROM sites CROSS JOIN (VALUES
    ('PROD-A', 'Production Shift A', 'PRODUCTION', '06:00'::time, '14:00'::time),
    ('PROD-B', 'Production Shift B', 'PRODUCTION', '14:00'::time, '22:00'::time),
    ('SAN', 'Sanitation Shift', 'SANITATION', '22:00'::time, '06:00'::time)
) AS v(shift_code, name, function, start_time, end_time) WHERE site_code = 'ATX';

INSERT INTO employees (site_id, employee_number, first_name, last_name, job_title, department)
SELECT site_id, v.* FROM sites CROSS JOIN (VALUES
    ('E001', 'Alex', 'Morgan', 'Maintenance Technician', 'MAINTENANCE'),
    ('E002', 'Jordan', 'Lee', 'Maintenance Technician', 'MAINTENANCE'),
    ('E003', 'Casey', 'Rivera', 'Line 1 Operator', 'PRODUCTION'),
    ('E004', 'Taylor', 'Brooks', 'Line 2 Operator', 'PRODUCTION'),
    ('E005', 'Morgan', 'Patel', 'Production Lead', 'PRODUCTION'),
    ('E006', 'Jamie', 'Nguyen', 'Line 1 Operator', 'PRODUCTION'),
    ('E007', 'Riley', 'Davis', 'Line 2 Operator', 'PRODUCTION'),
    ('E008', 'Avery', 'Kim', 'Production Lead', 'PRODUCTION'),
    ('E009', 'Cameron', 'Flores', 'Sanitation Lead', 'SANITATION'),
    ('E010', 'Drew', 'Wilson', 'Sanitation Technician', 'SANITATION')
) AS v(employee_number, first_name, last_name, job_title, department) WHERE site_code = 'ATX';

INSERT INTO employee_shift_assignments (employee_id, shift_id, effective_from)
SELECT e.employee_id, s.shift_id, DATE '2026-01-01'
FROM (VALUES
    ('E001','PROD-A'), ('E003','PROD-A'), ('E004','PROD-A'), ('E005','PROD-A'),
    ('E002','PROD-B'), ('E006','PROD-B'), ('E007','PROD-B'), ('E008','PROD-B'),
    ('E009','SAN'), ('E010','SAN')
) v(employee_number, shift_code)
JOIN employees e USING (employee_number)
JOIN shifts s USING (shift_code);

INSERT INTO assets (site_id, asset_code, name, equipment_type, scope)
SELECT site_id, v.* FROM sites CROSS JOIN (VALUES
    ('MIXER-101', 'Mixer-101', 'MIXER', 'DEDICATED_PRODUCTION'::asset_scope),
    ('CONVEYOR-101', 'Conveyor-101', 'CONVEYOR', 'DEDICATED_PRODUCTION'::asset_scope),
    ('FILLER-101', 'Filler-101', 'FILLER', 'DEDICATED_PRODUCTION'::asset_scope),
    ('LABELER-101', 'Labeler-101', 'LABELER', 'DEDICATED_PRODUCTION'::asset_scope),
    ('MIXER-201', 'Mixer-201', 'MIXER', 'DEDICATED_PRODUCTION'::asset_scope),
    ('CONVEYOR-201', 'Conveyor-201', 'CONVEYOR', 'DEDICATED_PRODUCTION'::asset_scope),
    ('FILLER-201', 'Filler-201', 'FILLER', 'DEDICATED_PRODUCTION'::asset_scope),
    ('LABELER-201', 'Labeler-201', 'LABELER', 'DEDICATED_PRODUCTION'::asset_scope),
    ('BLENDER-001', 'Blender-001', 'BLENDER', 'SHARED_PRODUCTION'::asset_scope),
    ('AIR-COMP-001', 'Air-Comp-001', 'AIR_COMPRESSOR', 'SHARED_UTILITY'::asset_scope)
) AS v(asset_code, name, equipment_type, scope) WHERE site_code = 'ATX';

INSERT INTO asset_line_relationships (asset_id, line_id, relationship_type, impact_priority)
SELECT a.asset_id, l.line_id, v.relationship_type::relationship_type, v.impact_priority
FROM (VALUES
    ('MIXER-101','LINE-1','DEDICATED',2), ('CONVEYOR-101','LINE-1','DEDICATED',2),
    ('FILLER-101','LINE-1','DEDICATED',1), ('LABELER-101','LINE-1','DEDICATED',2),
    ('MIXER-201','LINE-2','DEDICATED',2), ('CONVEYOR-201','LINE-2','DEDICATED',2),
    ('FILLER-201','LINE-2','DEDICATED',1), ('LABELER-201','LINE-2','DEDICATED',2),
    ('BLENDER-001','LINE-1','SCHEDULED_SHARED',1), ('BLENDER-001','LINE-2','SCHEDULED_SHARED',1),
    ('AIR-COMP-001','LINE-1','SIMULTANEOUS_DEPENDENCY',1), ('AIR-COMP-001','LINE-2','SIMULTANEOUS_DEPENDENCY',1)
) v(asset_code, line_code, relationship_type, impact_priority)
JOIN assets a USING (asset_code) JOIN production_lines l USING (line_code);

INSERT INTO asset_production_schedule (asset_id, line_id, scheduled_start, scheduled_end, production_order)
SELECT a.asset_id, l.line_id, v.scheduled_start, v.scheduled_end, v.production_order
FROM (VALUES
    ('LINE-1','2026-08-28 06:00-05'::timestamptz,'2026-08-28 09:00-05'::timestamptz,'PO-ATX-1001'),
    ('LINE-2','2026-08-28 09:00-05'::timestamptz,'2026-08-28 12:00-05'::timestamptz,'PO-ATX-2001'),
    ('LINE-1','2026-08-28 12:00-05'::timestamptz,'2026-08-28 14:00-05'::timestamptz,'PO-ATX-1002')
) v(line_code, scheduled_start, scheduled_end, production_order)
JOIN assets a ON a.asset_code='BLENDER-001' JOIN production_lines l USING (line_code);

INSERT INTO asset_criticality (asset_id, production_impact, safety_impact, food_safety_impact, quality_impact, redundancy, spare_parts_lead_time, repair_difficulty, shared_line_impact, criticality_class, rationale)
SELECT a.asset_id, v.production_impact, v.safety_impact, v.food_safety_impact, v.quality_impact, v.redundancy, v.spare_parts_lead_time, v.repair_difficulty, v.shared_line_impact, v.criticality_class, v.rationale
FROM (VALUES
    ('MIXER-101',4,2,3,3,4,2,3,1,'B','Dedicated Line 1 process equipment.'),
    ('CONVEYOR-101',4,2,2,3,4,2,2,1,'B','Dedicated Line 1 material handling.'),
    ('FILLER-101',5,3,4,5,5,3,4,1,'A','Production-critical filling constraint on Line 1.'),
    ('LABELER-101',3,2,2,4,3,2,2,1,'B','Dedicated Line 1 packaging equipment.'),
    ('MIXER-201',4,2,3,3,4,2,3,1,'B','Dedicated Line 2 process equipment.'),
    ('CONVEYOR-201',4,2,2,3,4,3,3,1,'B','Dedicated Line 2 conveyor with recurring tracking risk.'),
    ('FILLER-201',5,3,4,5,5,3,4,1,'A','Production-critical Line 2 filler and repeat-failure focus.'),
    ('LABELER-201',3,2,2,4,3,2,2,1,'B','Dedicated Line 2 packaging equipment.'),
    ('BLENDER-001',5,3,4,5,5,4,4,5,'A','Shared scheduled production equipment serving both lines.'),
    ('AIR-COMP-001',5,4,3,4,5,5,5,5,'PLANT_CRITICAL','No normal redundancy; simultaneous dependency for both lines.')
) v(asset_code, production_impact, safety_impact, food_safety_impact, quality_impact, redundancy, spare_parts_lead_time, repair_difficulty, shared_line_impact, criticality_class, rationale)
JOIN assets a USING (asset_code);

WITH frequencies(frequency, days, minutes, priority, shutdown) AS (VALUES
    ('WEEKLY'::pm_frequency,7,30,'MEDIUM'::priority_level,false),
    ('BIWEEKLY'::pm_frequency,14,45,'MEDIUM'::priority_level,false),
    ('MONTHLY'::pm_frequency,30,60,'HIGH'::priority_level,true),
    ('QUARTERLY'::pm_frequency,90,90,'HIGH'::priority_level,true),
    ('SEMIANNUAL'::pm_frequency,182,150,'HIGH'::priority_level,true)
)
INSERT INTO pm_plans (asset_id, pm_code, frequency, frequency_days, title, estimated_minutes, priority, requires_shutdown, safety_notes)
SELECT a.asset_id, 'PM-' || a.asset_code || '-' || f.frequency::text, f.frequency, f.days,
       a.name || ' ' || initcap(replace(f.frequency::text,'_',' ')) || ' PM', f.minutes, f.priority, f.shutdown,
       CASE WHEN f.shutdown THEN 'Follow lockout/tagout and equipment-specific food-safety controls.' ELSE 'Follow site safety and sanitation procedures.' END
FROM assets a CROSS JOIN frequencies f;

INSERT INTO pm_plan_revisions (pm_plan_id, revision_number, effective_from, change_reason)
SELECT pm_plan_id, 1, DATE '2026-01-01', 'Initial master-data release' FROM pm_plans;

WITH templates(equipment_type, frequency, tasks) AS (VALUES
('MIXER','WEEKLY','Inspect for product buildup|Check unusual noise or vibration|Inspect guards and fasteners|Check shaft seal for leakage|Verify emergency stop operation'),
('MIXER','BIWEEKLY','Inspect drive belt condition and tension|Inspect motor mounting hardware|Check sensor alignment|Inspect electrical cables and connectors'),
('MIXER','MONTHLY','Lubricate bearings where applicable|Inspect coupling and shaft alignment|Check motor current against baseline|Inspect VFD fault history|Check gearbox oil level'),
('MIXER','QUARTERLY','Inspect gearbox oil condition|Check motor insulation condition|Verify safety interlocks|Inspect internal electrical connections|Check bearing vibration trend'),
('MIXER','SEMIANNUAL','Replace gearbox oil where required|Detailed motor inspection|Inspect or replace worn seals|Verify shaft alignment|Full safety circuit verification|Review PM effectiveness against failure history'),
('CONVEYOR','WEEKLY','Inspect belt tracking|Inspect belt damage and wear|Check guards|Inspect rollers|Check for unusual vibration or noise'),
('CONVEYOR','BIWEEKLY','Check belt tension|Inspect guide rails|Inspect sensor alignment|Check roller mounting hardware'),
('CONVEYOR','MONTHLY','Lubricate bearings where required|Inspect drive chain or drive belt|Inspect gearmotor|Check motor current|Inspect electrical connections'),
('CONVEYOR','QUARTERLY','Check pulley and roller alignment|Inspect gearbox oil|Inspect frame fasteners|Verify safety devices|Trend drive assembly vibration'),
('CONVEYOR','SEMIANNUAL','Detailed belt inspection|Assess belt replacement need|Inspect drive gearbox|Inspect all bearings|Verify full alignment|Inspect wiring and control enclosure|Review recurring belt-tracking failures'),
('FILLER','WEEKLY','Inspect photoeyes|Check sensor mounts|Inspect pneumatic tubing|Inspect fill nozzles|Verify guards and interlocks|Check for air leaks'),
('FILLER','BIWEEKLY','Verify sensor alignment|Inspect pneumatic cylinders|Check solenoid valve operation|Inspect mounting hardware|Check regulator pressure'),
('FILLER','MONTHLY','Inspect drive system|Check bearing condition|Inspect electrical connections|Check motor current|Inspect valves and fittings|Review fault history'),
('FILLER','QUARTERLY','Inspect control cabinet|Verify safety circuits|Check pneumatic leakage rate|Inspect actuator wear|Perform vibration checks|Verify fill sequence timing'),
('FILLER','SEMIANNUAL','Replace critical seals|Inspect or rebuild selected pneumatic valves|Detailed drive inspection|Calibrate sensors where applicable|Verify machine alignment|Review PM effectiveness against failure history'),
('LABELER','WEEKLY','Clean label sensor|Inspect applicator rollers|Check label tracking|Inspect belts|Verify guards'),
('LABELER','BIWEEKLY','Inspect drive belt tension|Check sensor alignment|Inspect peel plate|Check mounting fasteners'),
('LABELER','MONTHLY','Inspect drive motor|Check bearings|Inspect electrical connections|Review fault history|Check encoder operation'),
('LABELER','QUARTERLY','Inspect internal control panel|Check motor current|Inspect complete label path|Verify safety devices|Inspect drive assembly'),
('LABELER','SEMIANNUAL','Replace worn rollers or belts as condition requires|Detailed sensor verification|Inspect motor and gearbox|Verify applicator alignment|Review recurring faults'),
('BLENDER','WEEKLY','Check seals for leakage|Inspect agitator or mixing shaft|Check abnormal noise and vibration|Inspect guards|Verify proximity sensors'),
('BLENDER','BIWEEKLY','Inspect coupling|Inspect motor and gearbox mounts|Verify load-cell readings|Inspect wiring|Check critical fasteners'),
('BLENDER','MONTHLY','Check gearbox oil level|Trend vibration|Check motor current|Inspect bearings|Review drive faults'),
('BLENDER','QUARTERLY','Inspect gearbox oil condition|Verify load-cell calibration|Inspect coupling alignment|Check electrical terminations|Verify safety interlocks'),
('BLENDER','SEMIANNUAL','Replace gearbox oil as required|Inspect shaft bearings|Inspect or rebuild seals|Detailed motor inspection|Verify alignment|Review shared-production dependency risk'),
('AIR_COMPRESSOR','WEEKLY','Check oil level|Inspect for leaks|Check operating pressure|Check discharge temperature|Listen for abnormal noise'),
('AIR_COMPRESSOR','BIWEEKLY','Inspect belts|Inspect intake filter|Drain moisture|Inspect cooling system|Check operating hours'),
('AIR_COMPRESSOR','MONTHLY','Record vibration|Check motor current|Inspect electrical connections|Inspect condensate system|Review alarms'),
('AIR_COMPRESSOR','QUARTERLY','Replace or inspect air filter|Inspect oil filter|Inspect belts and tension|Check pressure transducer|Inspect cooler'),
('AIR_COMPRESSOR','SEMIANNUAL','Change oil and filter if required|Replace separator element based on hours or condition|Detailed motor inspection|Inspect compressor element|Verify pressure controls|Review reliability trend')
), expanded AS (
  SELECT equipment_type, frequency::pm_frequency, task_description, ordinality::integer sequence_number
  FROM templates CROSS JOIN LATERAL regexp_split_to_table(tasks, '\|') WITH ORDINALITY AS t(task_description, ordinality)
)
INSERT INTO pm_tasks (pm_plan_id, revision_number, sequence_number, task_description, requires_shutdown, safety_note)
SELECT p.pm_plan_id, 1, e.sequence_number, e.task_description, p.requires_shutdown,
       CASE WHEN p.requires_shutdown THEN 'Apply lockout/tagout before intrusive inspection.' END
FROM expanded e JOIN assets a USING (equipment_type) JOIN pm_plans p ON p.asset_id=a.asset_id AND p.frequency=e.frequency;

INSERT INTO parts (part_number, description, unit_cost, quantity_on_hand, minimum_quantity, maximum_quantity, lead_time_days, critical_spare)
VALUES
('MC-01','Motor Contactor, common IEC size',185,4,2,6,14,true), ('MIX-BELT-01','Mixer Drive Belt',95,3,2,5,10,true),
('MIX-SEAL-01','Mixer Shaft Seal Kit',240,3,2,5,21,true), ('MIX-BRG-01','Mixing Shaft Bearing',310,2,1,4,28,true),
('PROX-01','Proximity Sensor, general purpose',125,5,2,8,10,true), ('VFD-FAN-01','VFD Cooling Fan',85,3,1,4,14,false),
('CONV-BELT-01','Conveyor Belt',1450,2,1,3,35,true), ('ROLLER-BRG-01','Drive Roller Bearing',135,4,2,6,14,true),
('IDLER-01','Conveyor Idler Roller',180,4,2,6,18,false), ('GEARMOTOR-01','Conveyor Gearmotor',1325,1,1,2,42,true),
('TRACK-SNS-01','Belt Tracking Sensor',260,2,1,4,21,true), ('PE-01','Photoelectric Sensor PE-01',175,6,3,10,14,true),
('FILL-BRKT-01','Filler Sensor Mounting Bracket',90,4,2,6,12,true), ('SOL-24V-01','24V Pneumatic Solenoid Valve',210,4,2,6,18,true),
('CYL-SEAL-01','Pneumatic Cylinder Seal Kit',72,6,3,10,12,false), ('NOZZLE-SEAL-01','Fill Nozzle Seal Kit',48,10,5,15,7,true),
('LABEL-SNS-01','Label Sensor',295,3,1,5,21,true), ('LABEL-BELT-01','Labeler Drive Belt',115,3,1,5,14,true),
('PRINT-ROLLER-01','Labeler Print Roller',380,2,1,3,28,false), ('APPL-ROLLER-01','Applicator Roller',265,2,1,4,21,true),
('DRIVE-FUSE-01','Motor Drive Fuse',28,8,4,12,7,false), ('BLEND-BRG-01','Blender Gearbox Bearing',425,2,1,3,35,true),
('BLEND-SEAL-01','Blender Shaft Seal Kit',360,2,1,3,28,true), ('LOAD-CELL-01','Blender Load Cell',780,1,1,2,45,true),
('BLEND-COUP-01','Blender Drive Coupling',520,1,1,3,35,true), ('AIR-FILTER-01','Compressor Air Filter Element',110,3,2,5,14,true),
('OIL-FILTER-01','Compressor Oil Filter',95,3,2,5,14,true), ('SEPARATOR-01','Compressor Separator Element',460,2,1,3,30,true),
('COMP-BELT-01','Compressor Drive Belt',185,2,1,4,18,true), ('PRESS-XDCR-01','Pressure Transducer',340,2,1,3,28,true);

WITH mapping(equipment_type, part_number, critical, notes) AS (VALUES
('MIXER','MC-01',true,'Motor control spare'),('MIXER','MIX-BELT-01',true,'Drive spare'),('MIXER','MIX-SEAL-01',true,'Product-zone seal'),('MIXER','MIX-BRG-01',true,'Long-lead rotating spare'),('MIXER','PROX-01',true,'Position sensing'),('MIXER','VFD-FAN-01',false,'Common cooling fan'),
('CONVEYOR','CONV-BELT-01',true,'Line-specific belt dimensions'),('CONVEYOR','ROLLER-BRG-01',true,'Drive roller bearing'),('CONVEYOR','IDLER-01',false,'Common idler'),('CONVEYOR','GEARMOTOR-01',true,'Long-lead drive'),('CONVEYOR','TRACK-SNS-01',true,'Tracking protection'),('CONVEYOR','PE-01',true,'Common photoeye'),
('FILLER','PE-01',true,'Shared between both fillers'),('FILLER','FILL-BRKT-01',true,'RCA-relevant bracket'),('FILLER','SOL-24V-01',true,'Common fill valve control'),('FILLER','CYL-SEAL-01',false,'Cylinder repair'),('FILLER','NOZZLE-SEAL-01',true,'Food-contact seal'),('FILLER','PROX-01',true,'Position sensing'),
('LABELER','LABEL-SNS-01',true,'Label registration'),('LABELER','LABEL-BELT-01',true,'Drive spare'),('LABELER','PRINT-ROLLER-01',false,'Print path wear item'),('LABELER','APPL-ROLLER-01',true,'Applicator wear item'),('LABELER','PROX-01',false,'Common sensor'),('LABELER','DRIVE-FUSE-01',false,'Electrical protection'),
('BLENDER','BLEND-BRG-01',true,'Shared asset gearbox bearing'),('BLENDER','MC-01',true,'Motor control spare'),('BLENDER','BLEND-SEAL-01',true,'Product-zone seal'),('BLENDER','LOAD-CELL-01',true,'Batch accuracy'),('BLENDER','PROX-01',true,'Position sensing'),('BLENDER','BLEND-COUP-01',true,'Long-lead drive coupling'),
('AIR_COMPRESSOR','AIR-FILTER-01',true,'Intake filtration'),('AIR_COMPRESSOR','OIL-FILTER-01',true,'Lubrication filtration'),('AIR_COMPRESSOR','SEPARATOR-01',true,'Long-lead service element'),('AIR_COMPRESSOR','COMP-BELT-01',true,'Drive spare'),('AIR_COMPRESSOR','PRESS-XDCR-01',true,'Pressure control'),('AIR_COMPRESSOR','MC-01',true,'Motor control spare')
)
INSERT INTO asset_parts (asset_id, part_id, quantity_required, critical_for_asset, notes)
SELECT a.asset_id, p.part_id, 1, m.critical, m.notes FROM mapping m JOIN assets a USING (equipment_type) JOIN parts p USING (part_number);

INSERT INTO inventory_transactions (part_id, transaction_type, quantity, reference, notes)
SELECT part_id, 'RECEIPT', quantity_on_hand, 'OPENING-BALANCE', 'Initial controlled inventory balance' FROM parts WHERE quantity_on_hand > 0;

INSERT INTO skills (skill_code, name, critical_skill) VALUES
('MECH','Mechanical',true),('ELEC','Electrical',true),('PLC','PLC',true),('PNEU','Pneumatics',true),
('FILL','Fillers',true),('MIX','Mixers',false),('CONV','Conveyors',false),('LABEL','Labelers',false);

INSERT INTO employee_skills (employee_id, skill_id, proficiency_level, assessed_on)
SELECT e.employee_id, s.skill_id, v.level, DATE '2026-08-01'
FROM (VALUES
('E001','MECH',4),('E001','ELEC',3),('E001','PLC',2),('E001','PNEU',4),('E001','FILL',4),('E001','MIX',3),('E001','CONV',4),('E001','LABEL',3),
('E002','MECH',3),('E002','ELEC',4),('E002','PLC',3),('E002','PNEU',3),('E002','FILL',3),('E002','MIX',4),('E002','CONV',3),('E002','LABEL',4)
) v(employee_number, skill_code, level) JOIN employees e USING (employee_number) JOIN skills s USING (skill_code);

INSERT INTO kpi_targets (site_id, kpi_code, display_name, comparison_operator, target_value, unit, effective_from)
SELECT site_id, v.* FROM sites CROSS JOIN (VALUES
('UPTIME','Uptime','>=',95,'PERCENT',DATE '2026-01-01'),('PM_COMPLIANCE','PM compliance','>=',98,'PERCENT',DATE '2026-01-01'),
('EMERGENCY_WO_PERCENT','Emergency work orders','<',30,'PERCENT',DATE '2026-01-01'),('MTTR_IMPROVEMENT','MTTR improvement','>=',15,'PERCENT',DATE '2026-01-01'),
('MTBF_IMPROVEMENT','MTBF improvement','>=',20,'PERCENT',DATE '2026-01-01'),('CRITICAL_SPARE_AVAILABILITY','Critical spare availability','>=',98,'PERCENT',DATE '2026-01-01'),
('REPEAT_FAILURE_REDUCTION','Repeat failure reduction','>=',30,'PERCENT',DATE '2026-01-01'),('WO_CLOSURE_RATE','Work order closure rate','>=',95,'PERCENT',DATE '2026-01-01'),
('CRITICAL_RESPONSE_MINUTES','Critical response time','<=',15,'MINUTES',DATE '2026-01-01')
) v(kpi_code, display_name, comparison_operator, target_value, unit, effective_from) WHERE site_code='ATX';

COMMIT;
