BEGIN;

-- Fixed demonstration period: 2026-01-01 through 2026-08-26.
-- This file is intentionally applied once after master data; use the guarded rebuild to rerun it.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM work_orders WHERE work_order_number LIKE 'WO-2026-%') THEN
        RAISE EXCEPTION 'Milestone 2 history already exists; use the guarded rebuild process.';
    END IF;
END $$;

WITH month_plan(month_no, month_start, emergency_count, failure_count, close_count) AS (VALUES
    (1,DATE '2026-01-01',12,12,20),(2,DATE '2026-02-01',11,11,21),
    (3,DATE '2026-03-01',10,10,22),(4,DATE '2026-04-01',9,9,22),
    (5,DATE '2026-05-01',9,8,23),(6,DATE '2026-06-01',8,8,23),
    (7,DATE '2026-07-01',8,6,24),(8,DATE '2026-08-01',7,6,23)
), generated AS (
    SELECT mp.*, n,
           ((month_no-1)*25+n) AS sequence_no,
           CASE
             WHEN month_no >= 7 AND n IN (2,3,4) THEN (ARRAY['MIXER-201','LABELER-201','FILLER-101'])[n-1]
             WHEN n BETWEEN 1 AND 4 THEN 'FILLER-201'
             WHEN n BETWEEN 5 AND 7 THEN 'CONVEYOR-201'
             WHEN n=8 THEN 'MIXER-201'
             WHEN n=9 THEN 'FILLER-101'
             WHEN n=10 THEN 'BLENDER-001'
             ELSE (ARRAY['MIXER-101','CONVEYOR-101','LABELER-101','LABELER-201','AIR-COMP-001'])[((n-11)%5)+1]
           END AS asset_code
    FROM month_plan mp CROSS JOIN generate_series(1,25) n
), classified AS (
    SELECT g.*,
           CASE WHEN n <= emergency_count THEN 'EMERGENCY'::work_type
                WHEN n <= emergency_count+5 THEN 'CORRECTIVE'::work_type
                WHEN n <= emergency_count+11 THEN 'PREVENTIVE'::work_type
                WHEN n <= emergency_count+13 THEN 'PREDICTIVE'::work_type
                WHEN n <= emergency_count+15 THEN 'SANITATION_FINDING'::work_type
                ELSE 'INSPECTION'::work_type END AS resolved_work_type,
           (month_start + ((n*3+month_no)%24) * interval '1 day' +
             CASE WHEN n%2=0 THEN interval '7 hours 10 minutes' ELSE interval '15 hours 20 minutes' END)::timestamptz AS base_requested
    FROM generated g
)
INSERT INTO work_orders (
    work_order_number,asset_id,work_type,priority,title,description,requested_at,acknowledged_at,
    work_started_at,work_completed_at,closed_at,status,emergency,planned,failure_code,cause_code,
    assigned_employee_id,labor_hours,labor_cost,parts_cost
)
SELECT 'WO-2026-'||lpad(sequence_no::text,4,'0'),a.asset_id,c.resolved_work_type,
       CASE WHEN c.resolved_work_type='EMERGENCY' AND c.n<=3 THEN 'CRITICAL'::priority_level
            WHEN c.resolved_work_type IN ('EMERGENCY','CORRECTIVE') THEN 'HIGH'::priority_level
            WHEN c.resolved_work_type='PREDICTIVE' THEN 'HIGH'::priority_level ELSE 'MEDIUM'::priority_level END,
       CASE
         WHEN asset_code='FILLER-201' AND n<=4 THEN CASE n WHEN 1 THEN 'Photoeye misalignment stops fill sequence' WHEN 2 THEN 'Repeat photoeye alignment fault' WHEN 3 THEN 'Intermittent photoeye signal fault' ELSE 'Sensor mounting bracket failure' END
         WHEN asset_code='CONVEYOR-201' AND n<=7 THEN CASE n%3 WHEN 0 THEN 'Conveyor belt tension correction' WHEN 1 THEN 'Belt tracking and alignment fault' ELSE 'Worn guide roller causing belt drift' END
         WHEN asset_code='BLENDER-001' AND month_no=4 AND n=10 THEN 'Shared blender drive coupling failure'
         WHEN asset_code='AIR-COMP-001' AND c.resolved_work_type='PREDICTIVE' THEN 'Compressor condition review and planned intervention'
         ELSE initcap(replace(c.resolved_work_type::text,'_',' '))||' work on '||a.name END,
       CASE
         WHEN asset_code='FILLER-201' AND n<=3 THEN 'Restore production by realigning sensor, tightening accessible hardware, and resetting the photoeye.'
         WHEN asset_code='FILLER-201' AND n=4 THEN 'Bracket movement observed under vibration; temporary hardware correction restored production.'
         WHEN asset_code='CONVEYOR-201' THEN 'Inspect tracking, guide rollers, belt tension, and mounting security; correct the immediate production issue.'
         ELSE 'Deterministic historical maintenance record for reliability trend analysis.' END,
       CASE WHEN asset_code='BLENDER-001' AND month_no=4 AND n=10 THEN '2026-04-11 08:15-05'::timestamptz ELSE base_requested END,
       (CASE WHEN asset_code='BLENDER-001' AND month_no=4 AND n=10 THEN '2026-04-11 08:15-05'::timestamptz ELSE base_requested END)
          + make_interval(mins => GREATEST(8,20-(month_no-1))),
       (CASE WHEN asset_code='BLENDER-001' AND month_no=4 AND n=10 THEN '2026-04-11 08:15-05'::timestamptz ELSE base_requested END)
          + make_interval(mins => GREATEST(12,24-(month_no-1))),
       (CASE WHEN asset_code='BLENDER-001' AND month_no=4 AND n=10 THEN '2026-04-11 08:15-05'::timestamptz ELSE base_requested END)
          + make_interval(mins => GREATEST(12,24-(month_no-1)) + CASE WHEN asset_code='BLENDER-001' AND month_no=4 AND n=10 THEN 90 ELSE 82-round(12.0*(month_no-1)/7)::integer+((n%5)-2)*3 END),
       CASE WHEN n<=close_count THEN
         (CASE WHEN asset_code='BLENDER-001' AND month_no=4 AND n=10 THEN '2026-04-11 08:15-05'::timestamptz ELSE base_requested END)
          + make_interval(mins => GREATEST(12,24-(month_no-1)) + CASE WHEN asset_code='BLENDER-001' AND month_no=4 AND n=10 THEN 110 ELSE 102-round(12.0*(month_no-1)/7)::integer+((n%5)-2)*3 END)
       END,
       CASE WHEN n<=close_count THEN 'CLOSED'::work_status ELSE 'COMPLETED'::work_status END,
       c.resolved_work_type='EMERGENCY', c.resolved_work_type IN ('PREVENTIVE','PREDICTIVE','INSPECTION'),
       CASE WHEN c.resolved_work_type IN ('EMERGENCY','CORRECTIVE') THEN
         CASE WHEN asset_code='FILLER-201' THEN 'SENSOR_FAULT' WHEN asset_code='CONVEYOR-201' THEN 'BELT_TRACKING' ELSE 'MECHANICAL_FAULT' END END,
       CASE WHEN asset_code='FILLER-201' THEN 'ALIGNMENT_OR_MOUNTING' WHEN asset_code='CONVEYOR-201' THEN 'ROLLER_ALIGNMENT' ELSE 'WEAR_OR_ADJUSTMENT' END,
       CASE WHEN n%2=0 THEN tech_b.employee_id ELSE tech_a.employee_id END,
       round((CASE WHEN asset_code='BLENDER-001' AND month_no=4 AND n=10 THEN 90 ELSE 82-round(12.0*(month_no-1)/7)::integer+((n%5)-2)*3 END)/60.0,2),
       round((CASE WHEN asset_code='BLENDER-001' AND month_no=4 AND n=10 THEN 90 ELSE 82-round(12.0*(month_no-1)/7)::integer+((n%5)-2)*3 END)/60.0*42,2),
       CASE WHEN c.resolved_work_type IN ('EMERGENCY','CORRECTIVE') THEN (35+(n%6)*45)::numeric ELSE 0 END
FROM classified c JOIN assets a USING(asset_code)
CROSS JOIN employees tech_a CROSS JOIN employees tech_b
WHERE tech_a.employee_number='E001' AND tech_b.employee_number='E002';

-- Failure history: 70 events. Repeat events fall from 11 in January to 5 in August.
WITH plan(month_no,failure_count,repeat_count) AS (VALUES
 (1,12,11),(2,11,10),(3,10,9),(4,9,8),(5,8,7),(6,8,7),(7,6,5),(8,6,5)
), selected AS (
 SELECT p.*,w.*,row_number() OVER(PARTITION BY p.month_no ORDER BY w.work_order_number) rn
 FROM plan p JOIN work_orders w ON extract(month FROM w.requested_at)=p.month_no
 WHERE w.work_type IN ('EMERGENCY','CORRECTIVE')
)
INSERT INTO failure_events(asset_id,work_order_id,failure_time,failure_mode,production_stopped,repeat_failure,notes)
SELECT asset_id,work_order_id,requested_at,
       CASE WHEN a.asset_code='FILLER-201' THEN CASE rn%4 WHEN 1 THEN 'PHOTOEYE_MISALIGNMENT' WHEN 2 THEN 'PHOTOEYE_MISALIGNMENT' WHEN 3 THEN 'PHOTOEYE_SIGNAL_FAULT' ELSE 'SENSOR_BRACKET_FAILURE' END
            WHEN a.asset_code='CONVEYOR-201' THEN CASE rn%3 WHEN 0 THEN 'BELT_TENSION' WHEN 1 THEN 'BELT_TRACKING' ELSE 'GUIDE_ROLLER_WEAR' END
            WHEN a.asset_code='BLENDER-001' THEN 'DRIVE_COUPLING_FAILURE'
            ELSE 'MECHANICAL_COMPONENT_FAILURE' END,
       true,rn<=repeat_count,
       CASE WHEN a.asset_code='FILLER-201' THEN 'Earlier repairs restored operation without fully removing bracket vibration.' END
FROM selected s JOIN assets a USING(asset_id) WHERE rn<=failure_count;

-- Exactly 80 unplanned downtime events with improving monthly totals.
WITH totals(month_no,total_minutes) AS (VALUES (1,6000),(2,5600),(3,5200),(4,4700),(5,4200),(6,3800),(7,3400),(8,3100)),
chosen AS (
 SELECT t.*,w.*,row_number() OVER(PARTITION BY t.month_no ORDER BY w.work_order_number) rn
 FROM totals t JOIN work_orders w ON extract(month FROM w.requested_at)=t.month_no
 WHERE w.work_type IN ('EMERGENCY','CORRECTIVE')
), prepared AS (
 SELECT c.*,a.asset_code,
   CASE WHEN c.month_no=4 AND a.asset_code='BLENDER-001' AND c.rn=10 THEN 90
        ELSE round((c.total_minutes-CASE WHEN c.month_no=4 THEN 90 ELSE 0 END)::numeric/(CASE WHEN c.month_no=4 THEN 9 ELSE 10 END))::integer END duration_minutes
 FROM chosen c JOIN assets a USING(asset_id) WHERE rn<=10
), inserted AS (
 INSERT INTO downtime_events(asset_id,work_order_id,downtime_start,downtime_end,planned,reason,production_impact,estimated_delay_minutes)
 SELECT asset_id,work_order_id,
        CASE WHEN month_no=4 AND asset_code='BLENDER-001' THEN '2026-04-11 08:15-05'::timestamptz ELSE requested_at END,
        CASE WHEN month_no=4 AND asset_code='BLENDER-001' THEN '2026-04-11 09:45-05'::timestamptz ELSE requested_at+make_interval(mins=>duration_minutes) END,
        false,title,
        CASE WHEN asset_code='BLENDER-001' THEN 'FUTURE_RISK' WHEN asset_code='AIR-COMP-001' THEN 'PLANT_WIDE' ELSE 'CURRENT_LINE' END,
        CASE WHEN asset_code='BLENDER-001' THEN 45 ELSE duration_minutes END
 FROM prepared RETURNING downtime_event_id,asset_id,work_order_id,
    EXTRACT(epoch FROM (downtime_end-downtime_start))/60.0 AS duration_minutes
)
INSERT INTO downtime_affected_lines(downtime_event_id,line_id,impact_type,delay_minutes)
SELECT i.downtime_event_id,l.line_id,'IMMEDIATE',i.duration_minutes::integer
FROM inserted i JOIN assets a USING(asset_id)
JOIN asset_line_relationships alr USING(asset_id) JOIN production_lines l USING(line_id)
WHERE alr.relationship_type <> 'SCHEDULED_SHARED'
UNION ALL
SELECT i.downtime_event_id,l.line_id,'IMMEDIATE',90
FROM inserted i JOIN assets a USING(asset_id) JOIN production_lines l ON l.line_code='LINE-1'
WHERE a.asset_code='BLENDER-001'
UNION ALL
SELECT i.downtime_event_id,l.line_id,'FUTURE_RISK',45
FROM inserted i JOIN assets a USING(asset_id) JOIN production_lines l ON l.line_code='LINE-2'
WHERE a.asset_code='BLENDER-001';

-- Daily sequential Blender schedule; the April event overlaps Line 1 and puts the next Line 2 slot at risk.
INSERT INTO asset_production_schedule(asset_id,line_id,scheduled_start,scheduled_end,production_order,status)
SELECT a.asset_id,l.line_id,d.day+t.start_time,d.day+t.end_time,
       'BLEND-'||to_char(d.day,'YYYYMMDD')||'-'||t.slot,
       CASE WHEN d.day+t.end_time < '2026-08-27 00:00-05'::timestamptz THEN 'COMPLETED' ELSE 'SCHEDULED' END
FROM generate_series('2026-01-01'::date,'2026-08-26'::date,interval '1 day') d(day)
CROSS JOIN (VALUES
 ('LINE-1','1',interval '6 hours',interval '9 hours'),
 ('LINE-2','2',interval '9 hours',interval '12 hours'),
 ('LINE-1','3',interval '12 hours',interval '14 hours')
) t(line_code,slot,start_time,end_time)
JOIN assets a ON a.asset_code='BLENDER-001' JOIN production_lines l USING(line_code);

-- 650 PM executions across all five frequencies with improving on-time completion.
WITH schedule AS (
 SELECT p.pm_plan_id,p.asset_id,p.frequency,d.scheduled_date::date,
        row_number() OVER(PARTITION BY date_trunc('month',d.scheduled_date) ORDER BY p.pm_plan_id,d.scheduled_date) AS monthly_row
 FROM pm_plans p CROSS JOIN LATERAL (
   SELECT gs AS scheduled_date FROM generate_series(
      DATE '2026-01-05',DATE '2026-08-26',
      CASE p.frequency WHEN 'WEEKLY' THEN interval '7 days' WHEN 'BIWEEKLY' THEN interval '14 days'
           WHEN 'MONTHLY' THEN interval '1 month' WHEN 'QUARTERLY' THEN interval '3 months' ELSE interval '6 months' END
   ) gs
 ) d
), scored AS (
 SELECT s.*,CASE extract(month FROM scheduled_date)::int
   WHEN 1 THEN 72 WHEN 2 THEN 76 WHEN 3 THEN 81 WHEN 4 THEN 85
   WHEN 5 THEN 89 WHEN 6 THEN 92 WHEN 7 THEN 95 ELSE 96 END threshold
 FROM schedule s
)
INSERT INTO pm_executions(pm_plan_id,revision_number,scheduled_date,completed_date,technician_id,status,completion_notes)
SELECT s.pm_plan_id,
       1,
       scheduled_date,
       scheduled_date + CASE WHEN (monthly_row*37+pm_plan_id)%100 < threshold THEN 0 ELSE 2 END,
       CASE WHEN pm_plan_id%2=0 THEN e2.employee_id ELSE e1.employee_id END,
       'COMPLETED',
       CASE WHEN (monthly_row*37+pm_plan_id)%100 < threshold THEN 'Completed on schedule.' ELSE 'Completed late; backlog recovery tracked.' END
FROM scored s JOIN pm_plans p USING(pm_plan_id) JOIN assets a ON a.asset_id=s.asset_id
CROSS JOIN employees e1 CROSS JOIN employees e2 WHERE e1.employee_number='E001' AND e2.employee_number='E002';

-- Twelve RCAs, including the major Filler-201 bracket investigation.
WITH candidates AS (
 SELECT w.*,row_number() OVER(ORDER BY requested_at) rn FROM work_orders w
 WHERE w.work_type IN ('EMERGENCY','CORRECTIVE') AND w.work_order_number IN (
   'WO-2026-0004','WO-2026-0029','WO-2026-0055','WO-2026-0079','WO-2026-0104','WO-2026-0129',
   'WO-2026-0155','WO-2026-0179','WO-2026-0007','WO-2026-0057','WO-2026-0107','WO-2026-0157')
)
INSERT INTO rca_events(rca_number,work_order_id,problem_statement,root_cause,analysis_method,opened_at,completed_at,status)
SELECT 'RCA-2026-'||lpad(rn::text,3,'0'),work_order_id,
       CASE WHEN work_order_number='WO-2026-0104' THEN 'Filler-201 experienced repeated sensor alignment and signal failures despite repeated restoration work.' ELSE 'Recurring production interruption requires structured cause review.' END,
       CASE WHEN work_order_number='WO-2026-0104' THEN 'Machine vibration loosened sensor mounting hardware. The weak mounting arrangement lacked an adequate locking method, and the weekly PM checked operation without explicitly verifying bracket security.'
            ELSE CASE WHEN a.asset_code='CONVEYOR-201' THEN 'Guide roller wear, belt alignment, tension, and mounting looseness combined to cause repeated tracking loss.' ELSE 'Wear and insufficient inspection detail allowed recurrence.' END END,
       CASE WHEN work_order_number='WO-2026-0104' THEN '5 WHY + CAUSE AND EFFECT' ELSE '5 WHY' END,
       requested_at+interval '1 day',requested_at+interval '10 days','COMPLETED'
FROM candidates c JOIN assets a USING(asset_id);

-- Revise the Filler-201 weekly PM without deleting revision 1.
UPDATE pm_plan_revisions SET effective_to=DATE '2026-05-31'
WHERE pm_plan_id=(SELECT p.pm_plan_id FROM pm_plans p JOIN assets a USING(asset_id) WHERE a.asset_code='FILLER-201' AND p.frequency='WEEKLY') AND revision_number=1;

INSERT INTO pm_plan_revisions(pm_plan_id,revision_number,effective_from,change_reason,rca_event_id)
SELECT p.pm_plan_id,2,DATE '2026-06-01','RCA correction: make bracket integrity and locking method explicit.',r.rca_event_id
FROM pm_plans p JOIN assets a USING(asset_id) CROSS JOIN rca_events r JOIN work_orders w USING(work_order_id)
WHERE a.asset_code='FILLER-201' AND p.frequency='WEEKLY' AND w.work_order_number='WO-2026-0104';

INSERT INTO pm_tasks(pm_plan_id,revision_number,sequence_number,task_description,requires_shutdown,safety_note)
SELECT p.pm_plan_id,2,t.sequence_number,t.task_description,false,'Follow site safety and sanitation procedures.'
FROM pm_plans p JOIN assets a USING(asset_id) CROSS JOIN (VALUES
 (1,'Inspect photoeyes'),(2,'Verify sensor bracket security'),(3,'Verify locking hardware is present and secure'),
 (4,'Inspect bracket for fatigue or damage'),(5,'Confirm sensor alignment after bracket inspection'),
 (6,'Inspect pneumatic tubing'),(7,'Inspect fill nozzles'),(8,'Verify guards and interlocks'),(9,'Check for air leaks')
) t(sequence_number,task_description)
WHERE a.asset_code='FILLER-201' AND p.frequency='WEEKLY';

UPDATE pm_plans SET current_revision=2,updated_at='2026-06-01 08:00-05'
WHERE pm_plan_id=(SELECT p.pm_plan_id FROM pm_plans p JOIN assets a USING(asset_id) WHERE a.asset_code='FILLER-201' AND p.frequency='WEEKLY');

UPDATE pm_executions SET revision_number=2
WHERE pm_plan_id=(SELECT p.pm_plan_id FROM pm_plans p JOIN assets a USING(asset_id) WHERE a.asset_code='FILLER-201' AND p.frequency='WEEKLY')
  AND scheduled_date>=DATE '2026-06-01';

INSERT INTO corrective_actions(rca_event_id,action_description,owner_employee_id,due_date,completed_date,action_type,verified_effectiveness,verification_notes)
SELECT r.rca_event_id,
       CASE n WHEN 1 THEN CASE WHEN w.work_order_number='WO-2026-0104' THEN 'Replace damaged Filler-201 sensor bracket and install locking hardware.' ELSE 'Complete permanent component repair.' END
              WHEN 2 THEN CASE WHEN w.work_order_number='WO-2026-0104' THEN 'Revise weekly Filler-201 PM to verify bracket security, locking hardware, fatigue, and alignment.' ELSE 'Update inspection content for the identified failure mechanism.' END
              ELSE CASE WHEN w.work_order_number='WO-2026-0104' THEN 'Inspect equivalent filler equipment, verify bracket spare, and monitor recurrence.' ELSE 'Verify effectiveness using subsequent failure history.' END END,
       e.employee_id,(r.completed_at::date+14+n),(r.completed_at::date+5+n),
       CASE n WHEN 1 THEN 'REPAIR'::action_type WHEN 2 THEN 'PM_REVISION'::action_type ELSE 'INSPECTION'::action_type END,
       true,'No equivalent recurrence observed after the verification period.'
FROM rca_events r JOIN work_orders w USING(work_order_id) CROSS JOIN generate_series(1,3)n CROSS JOIN employees e
WHERE e.employee_number=CASE WHEN n%2=0 THEN 'E001' ELSE 'E002' END;

INSERT INTO corrective_actions(rca_event_id,action_description,owner_employee_id,due_date,completed_date,action_type,verified_effectiveness,verification_notes)
SELECT r.rca_event_id,v.description,e.employee_id,v.due_date,v.completed_date,v.action_type,true,'Action included in reliability review.'
FROM rca_events r JOIN work_orders w USING(work_order_id)
CROSS JOIN (VALUES
 ('Inspect Filler-101 equivalent sensor mounting arrangement.',DATE '2026-06-12',DATE '2026-06-08','INSPECTION'::action_type),
 ('Confirm FILL-BRKT-01 and PE-01 spare-parts coverage.',DATE '2026-06-12',DATE '2026-06-09','SPARE_PART_UPDATE'::action_type),
 ('Trend Filler-201 sensor failure rate for 60 days.',DATE '2026-08-15',DATE '2026-08-15','OTHER'::action_type)
) v(description,due_date,completed_date,action_type) CROSS JOIN employees e
WHERE w.work_order_number='WO-2026-0104' AND e.employee_number='E001';

-- Thirty-six sanitation findings; sixteen link to maintenance work orders.
WITH findings AS (
 SELECT n,DATE '2026-01-01'+((n-1)*6) AS finding_date,
   (ARRAY['FILLER-101','CONVEYOR-201','FILLER-201','MIXER-101','LABELER-201','CONVEYOR-101'])[((n-1)%6)+1] asset_code,
   (ARRAY['Loose guard fastener','Damaged conveyor belt edge','Product buildup near sensor bracket','Minor mixer seal leak','Damaged cable protection','Abnormal noise during washdown','Loose mounting hardware','Water intrusion concern','Worn gasket or seal'])[((n-1)%9)+1] description
 FROM generate_series(1,36)n
), sanitation_wos AS (
 SELECT work_order_id,row_number() OVER(ORDER BY requested_at) rn FROM work_orders WHERE work_type='SANITATION_FINDING'
)
INSERT INTO sanitation_findings(finding_number,asset_id,reported_by,reported_at,description,priority,maintenance_required,startup_risk,work_order_id,status)
SELECT 'SAN-2026-'||lpad(f.n::text,3,'0'),a.asset_id,e.employee_id,f.finding_date+time '22:35',f.description,
       CASE WHEN f.n IN (18,31) THEN 'HIGH'::priority_level WHEN f.n%3=0 THEN 'MEDIUM'::priority_level ELSE 'LOW'::priority_level END,
       f.n%3<>1,f.n IN (18,31),sw.work_order_id,
       CASE WHEN sw.work_order_id IS NOT NULL THEN 'RESOLVED'::finding_status ELSE 'CLOSED'::finding_status END
FROM findings f JOIN assets a USING(asset_code) CROSS JOIN employees e
LEFT JOIN sanitation_wos sw ON sw.rn=f.n
WHERE e.employee_number=CASE WHEN f.n%2=0 THEN 'E009' ELSE 'E010' END;

-- Keep one late-August startup-risk finding open for the operational-risk dashboard.
INSERT INTO sanitation_findings(finding_number,asset_id,reported_by,reported_at,description,priority,maintenance_required,startup_risk,status)
SELECT 'SAN-2026-037',a.asset_id,e.employee_id,'2026-08-26 23:20-05','Damaged belt edge requires inspection before next startup.','HIGH',true,true,'OPEN'
FROM assets a CROSS JOIN employees e WHERE a.asset_code='CONVEYOR-201' AND e.employee_number='E009';

-- Reset the opening inventory ledger to a deterministic January state.
WITH critical_ranks AS (
 SELECT part_id,row_number() OVER(ORDER BY part_number) critical_rank FROM parts WHERE critical_spare
), ranked AS (
 SELECT p.part_id,p.minimum_quantity,p.maximum_quantity,p.critical_spare,cr.critical_rank
 FROM parts p LEFT JOIN critical_ranks cr USING(part_id)
)
UPDATE inventory_transactions it SET transaction_at='2026-01-01 05:00-06',
 quantity=CASE WHEN r.critical_spare AND r.critical_rank<=4 THEN GREATEST(0.5,r.minimum_quantity-1) ELSE GREATEST(1,r.minimum_quantity) END,
 reference='OPENING-BALANCE-2026',notes='Deterministic opening inventory balance'
FROM ranked r WHERE it.part_id=r.part_id AND it.reference='OPENING-BALANCE';

-- Correct three of four early critical shortages over the improvement period.
WITH short_parts AS (
 SELECT p.part_id,row_number() OVER(ORDER BY p.part_number) rn FROM parts p
 WHERE p.critical_spare ORDER BY p.part_number LIMIT 4
)
INSERT INTO inventory_transactions(part_id,transaction_type,quantity,transaction_at,reference,notes)
SELECT part_id,'RECEIPT',1,
       CASE rn WHEN 1 THEN '2026-04-10 09:00-05'::timestamptz WHEN 2 THEN '2026-06-10 09:00-05'::timestamptz ELSE '2026-08-10 09:00-05'::timestamptz END,
       'PO-REPLENISH-'||rn,'Critical-spare replenishment program'
FROM short_parts WHERE rn<=3;

INSERT INTO inventory_transactions(part_id,transaction_type,quantity,transaction_at,work_order_id,reference,notes)
SELECT p.part_id,'ISSUE',-1,w.work_completed_at,w.work_order_id,'WO-PART-ISSUE','Part issued to historical repair'
FROM (VALUES ('PE-01','WO-2026-0104'),('FILL-BRKT-01','WO-2026-0104'),('ROLLER-BRG-01','WO-2026-0079'),('COMP-BELT-01','WO-2026-0148')) v(part_number,work_order_number)
JOIN parts p USING(part_number) JOIN work_orders w USING(work_order_number);

INSERT INTO inventory_transactions(part_id,transaction_type,quantity,transaction_at,reference,notes)
SELECT p.part_id,'RECEIPT',1,w.work_completed_at-interval '2 days','EXPEDITE-'||p.part_number,'Receipt supporting planned or corrective work'
FROM (VALUES ('PE-01','WO-2026-0104'),('FILL-BRKT-01','WO-2026-0104'),('ROLLER-BRG-01','WO-2026-0079'),('COMP-BELT-01','WO-2026-0148')) v(part_number,work_order_number)
JOIN parts p USING(part_number) JOIN work_orders w USING(work_order_number);

UPDATE parts p SET quantity_on_hand=x.balance
FROM (SELECT part_id,sum(quantity) balance FROM inventory_transactions GROUP BY part_id)x WHERE x.part_id=p.part_id;

-- Labor, parts, and planned/reactive overtime costs.
INSERT INTO maintenance_costs(work_order_id,asset_id,employee_id,cost_date,cost_category,amount,description)
SELECT work_order_id,asset_id,assigned_employee_id,work_completed_at::date,'LABOR',labor_cost,'Technician labor'
FROM work_orders;

INSERT INTO maintenance_costs(work_order_id,asset_id,cost_date,cost_category,amount,description)
SELECT work_order_id,asset_id,work_completed_at::date,'PARTS',parts_cost,'Repair parts consumed'
FROM work_orders WHERE parts_cost>0;

WITH months(month_no,month_start,reactive_cost,planned_cost) AS (VALUES
 (1,DATE '2026-01-01',950,240),(2,DATE '2026-02-01',850,280),(3,DATE '2026-03-01',760,320),(4,DATE '2026-04-01',650,390),
 (5,DATE '2026-05-01',560,430),(6,DATE '2026-06-01',470,520),(7,DATE '2026-07-01',380,590),(8,DATE '2026-08-01',300,640)
)
INSERT INTO maintenance_costs(asset_id,employee_id,cost_date,cost_category,amount,overtime_type,description)
SELECT a.asset_id,e.employee_id,m.month_start+24,'OVERTIME',v.amount,v.kind,
       CASE v.kind WHEN 'REACTIVE' THEN 'Breakdown response beyond normal production shift' ELSE 'Scheduled sanitation-window reliability work' END
FROM months m CROSS JOIN LATERAL (VALUES ('REACTIVE'::overtime_type,m.reactive_cost),('PLANNED'::overtime_type,m.planned_cost))v(kind,amount)
JOIN assets a ON a.asset_code=CASE WHEN v.kind='PLANNED' THEN 'AIR-COMP-001' ELSE 'FILLER-201' END
JOIN employees e ON e.employee_number=CASE WHEN v.kind='PLANNED' THEN 'E002' ELSE 'E001' END;

INSERT INTO capital_projects(project_code,site_id,asset_id,name,description,status,estimated_cost,approved_budget,estimated_annual_savings,planned_start,planned_end)
SELECT 'CAP-2026-001',s.site_id,a.asset_id,'Conveyor-201 Drive Reliability Improvement',
       'Upgrade guide rollers, tracking components, and drive alignment to reduce recurring production loss.',
       'APPROVED',18500,18500,36000,DATE '2026-09-15',DATE '2026-10-15'
FROM sites s JOIN assets a ON a.site_id=s.site_id AND a.asset_code='CONVEYOR-201';

-- Weekly Air-Comp-001 readings. Vibration rises from about 1.6 to 3.2 mm/s while the compressor stays operational.
WITH dates AS (
 SELECT gs::date measured_date,row_number() OVER(ORDER BY gs) rn,count(*) OVER() total
 FROM generate_series(DATE '2026-01-05',DATE '2026-08-24',interval '7 days')gs
), measures(measurement_type,unit,start_value,end_value,warning,alarm,direction) AS (VALUES
 ('VIBRATION','mm/s',1.55,3.20,2.80,4.50,'HIGH'),
 ('DISCHARGE_TEMPERATURE','degC',78.0,92.0,90.0,100.0,'HIGH'),
 ('MOTOR_CURRENT','A',42.0,48.5,48.0,55.0,'HIGH'),
 ('DISCHARGE_PRESSURE','psi',109.0,104.0,100.0,95.0,'LOW'),
 ('OPERATING_HOURS','hours',12400.0,16320.0,NULL,NULL,'HIGH')
)
INSERT INTO condition_measurements(asset_id,measurement_type,measured_at,numeric_value,unit,warning_threshold,alarm_threshold,threshold_direction,source,notes)
SELECT a.asset_id,m.measurement_type,d.measured_date+time '10:00',
       round((m.start_value+(m.end_value-m.start_value)*(d.rn-1)/NULLIF(d.total-1,0)+CASE WHEN m.measurement_type='VIBRATION' THEN ((d.rn%3)-1)*0.025 ELSE 0 END)::numeric,3),
       m.unit,m.warning,m.alarm,m.direction,'WEEKLY_CONDITION_ROUTE',
       CASE WHEN d.rn=d.total THEN 'Trend triggered predictive work planning during sanitation.' END
FROM dates d CROSS JOIN measures m JOIN assets a ON a.asset_code='AIR-COMP-001';

-- Planned predictive response during sanitation; asset remains operational and no unplanned compressor downtime is recorded.
INSERT INTO work_orders(work_order_number,asset_id,work_type,priority,title,description,requested_at,acknowledged_at,work_started_at,work_completed_at,closed_at,status,emergency,planned,assigned_employee_id,labor_hours,labor_cost,parts_cost)
SELECT 'WO-2026-0201',a.asset_id,'PREDICTIVE','HIGH','Air compressor vibration inspection during sanitation',
       'Inspect bearings, belt, alignment, and lubrication in a planned sanitation window before functional failure.',
       '2026-08-24 13:00-05','2026-08-24 13:08-05','2026-08-24 22:30-05','2026-08-25 01:00-05','2026-08-25 08:00-05',
       'CLOSED',false,true,e.employee_id,2.5,157.50,185
FROM assets a CROSS JOIN employees e WHERE a.asset_code='AIR-COMP-001' AND e.employee_number='E002';

INSERT INTO maintenance_costs(work_order_id,asset_id,employee_id,cost_date,cost_category,amount,description)
SELECT work_order_id,asset_id,assigned_employee_id,work_completed_at::date,'LABOR',labor_cost,'Planned predictive labor' FROM work_orders WHERE work_order_number='WO-2026-0201';

COMMIT;
