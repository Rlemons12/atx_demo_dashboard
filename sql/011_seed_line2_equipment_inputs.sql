BEGIN;

INSERT INTO stop_reason_definitions
    (stop_reason_code,display_name,loss_category,responsible_function,planned,maintenance_related,automatic_detection_allowed,default_priority,description)
VALUES
('NO_SCHEDULE','No Production Scheduled','PLANNED','SCHEDULING',true,false,true,1,'Unused calendar capacity outside the production schedule; not a failure.'),
('SANITATION','Sanitation','PLANNED','SANITATION',true,false,true,2,'Planned sanitation outside scheduled production.'),
('PLANNED_MAINTENANCE','Planned Maintenance','PLANNED','MAINTENANCE',true,true,true,3,'Planned maintenance performed outside scheduled production.'),
('BREAK_TIME','Break Time','PLANNED','OPERATIONS',true,false,true,4,'Planned break; excluded from scheduled production under the preserved demo convention.'),
('CHANGEOVER','Changeover','PLANNED','OPERATIONS',true,false,true,5,'Planned changeover inside the scheduled production window.'),
('ESTOP_PUSHED','E-Stop Pushed','SAFETY','SAFETY',false,false,true,10,'Safety stop; not maintenance-attributable without additional evidence.'),
('GUARD_OPEN','Guard Open','SAFETY','SAFETY',false,false,true,11,'Safety circuit open at a machine guard.'),
('PHOTOEYE_FAULT','Photoeye Fault','EQUIPMENT_MAINTENANCE','MAINTENANCE',false,true,true,20,'Explicit photoeye fault or intermittent/misaligned photoeye evidence.'),
('SENSOR_FAULT','Sensor Fault','EQUIPMENT_MAINTENANCE','MAINTENANCE',false,true,true,21,'Explicit non-photoeye sensor fault.'),
('MECHANICAL_FAULT','Mechanical Fault','EQUIPMENT_MAINTENANCE','MAINTENANCE',false,true,true,22,'Confirmed mechanical equipment fault.'),
('ELECTRICAL_FAULT','Electrical Fault','EQUIPMENT_MAINTENANCE','MAINTENANCE',false,true,true,23,'Confirmed electrical equipment fault.'),
('CONTROLS_FAULT','Controls Fault','EQUIPMENT_MAINTENANCE','MAINTENANCE',false,true,true,24,'Confirmed control-system fault.'),
('BELT_TRACKING_FAULT','Belt Tracking Fault','EQUIPMENT_MAINTENANCE','MAINTENANCE',false,true,true,25,'Conveyor belt tracking deviation confirmed as an equipment fault.'),
('COMMODITY_JAM','Commodity / Product Jam','PROCESS','SHARED / CROSS_FUNCTIONAL',false,false,true,30,'Commodity jam; diagnosis is required before attributing maintenance responsibility.'),
('PRODUCT_JAM','Product Jam','PROCESS','SHARED / CROSS_FUNCTIONAL',false,false,true,31,'Product flow jam; not automatically maintenance-related.'),
('WAITING_DOWNSTREAM','Waiting on Downstream','PRODUCTION_DEPENDENCY','OPERATIONS',false,false,true,40,'Asset is ready but inhibited by unavailable takeaway/downstream equipment.'),
('WAITING_UPSTREAM','Waiting on Upstream','PRODUCTION_DEPENDENCY','OPERATIONS',false,false,true,41,'Asset is ready but its infeed/upstream source is unavailable.'),
('MATERIAL_SHORTAGE','Material Shortage','MATERIAL','MATERIALS',false,false,true,50,'Required production material is unavailable.'),
('QUALITY_HOLD','Quality Hold','QUALITY','QUALITY',false,false,true,51,'Production is held by a quality disposition.'),
('OPERATOR_DELAY','Operator Delay','OPERATIONS','OPERATIONS',false,false,false,52,'Operational delay supported by operator or schedule evidence.'),
('UNCLASSIFIED_STOP','Unclassified Stop','UNKNOWN','UNKNOWN',false,false,true,99,'Evidence is insufficient for a more confident primary reason.')
ON CONFLICT (stop_reason_code) DO NOTHING;

WITH definitions(asset_code,suffix,sensor_type,unit,functional_class,description) AS (
 VALUES
 ('MIXER-201','RUN_STATE','DISCRETE',NULL,'MACHINE_RUN_STATE','Mixer actual run state'),
 ('MIXER-201','FAULT_STATE','DISCRETE',NULL,'FAULT_STATE','Mixer fault state'),
 ('MIXER-201','BATCH_COUNT','COUNTER','batch','BATCH_COUNT','Completed batch equivalent counter'),
 ('MIXER-201','BATCH_CYCLE','ANALOG','min/batch','BATCH_CYCLE_TIME','Actual batch-cycle equivalent'),
 ('MIXER-201','MOTOR_CURRENT','ANALOG','A','MOTOR_CURRENT','Mixer motor current'),
 ('MIXER-201','TEMPERATURE','ANALOG','degC','TEMPERATURE','Mixer product temperature'),
 ('MIXER-201','VIBRATION','ANALOG','mm/s','VIBRATION','Mixer motor vibration'),
 ('CONVEYOR-201','RUN_STATE','DISCRETE',NULL,'MACHINE_RUN_STATE','Conveyor actual run state'),
 ('CONVEYOR-201','FAULT_STATE','DISCRETE',NULL,'FAULT_STATE','Conveyor fault state'),
 ('CONVEYOR-201','PRODUCT_COUNT','COUNTER','units','TOTAL_COUNT','Conveyor product counter'),
 ('CONVEYOR-201','SPEED','ANALOG','units/min','ACTUAL_RATE','Conveyor line speed'),
 ('CONVEYOR-201','JAM_STATE','DISCRETE',NULL,'JAM_STATE','Product jam input'),
 ('CONVEYOR-201','MOTOR_CURRENT','ANALOG','A','MOTOR_CURRENT','Conveyor drive current'),
 ('CONVEYOR-201','BELT_TRACKING','ANALOG','mm','BELT_TRACKING','Belt centerline deviation'),
 ('FILLER-201','RUN_STATE','DISCRETE',NULL,'MACHINE_RUN_STATE','Filler actual run state'),
 ('FILLER-201','FAULT_STATE','DISCRETE',NULL,'FAULT_STATE','Filler fault state'),
 ('FILLER-201','TOTAL_COUNT','COUNTER','units','TOTAL_COUNT','Filler total production counter'),
 ('FILLER-201','GOOD_COUNT','COUNTER','units','GOOD_COUNT','Filler good production counter'),
 ('FILLER-201','REJECT_COUNT','COUNTER','units','REJECT_COUNT','Filler reject counter'),
 ('FILLER-201','ACTUAL_RATE','ANALOG','units/min','ACTUAL_RATE','Filler actual production rate'),
 ('FILLER-201','PHOTOEYE_STATE','DISCRETE',NULL,'PHOTOEYE_STATE','Filler product photoeye state'),
 ('FILLER-201','PHOTOEYE_FAULT','DISCRETE',NULL,'PHOTOEYE_FAULT','Filler photoeye diagnostic fault'),
 ('FILLER-201','CYCLE_TIME','ANALOG','sec/unit','CYCLE_TIME','Filler observed cycle time'),
 ('LABELER-201','RUN_STATE','DISCRETE',NULL,'MACHINE_RUN_STATE','Labeler actual run state'),
 ('LABELER-201','FAULT_STATE','DISCRETE',NULL,'FAULT_STATE','Labeler fault state'),
 ('LABELER-201','TOTAL_COUNT','COUNTER','units','TOTAL_COUNT','Labeler total production counter'),
 ('LABELER-201','REJECT_COUNT','COUNTER','units','REJECT_COUNT','Label reject counter'),
 ('LABELER-201','ACTUAL_RATE','ANALOG','units/min','ACTUAL_RATE','Labeler actual production rate'),
 ('LABELER-201','LABEL_PRESENT','DISCRETE',NULL,'LABEL_PRESENT_STATE','Label-present inspection input'),
 ('LABELER-201','CYCLE_TIME','ANALOG','sec/unit','CYCLE_TIME','Labeler observed cycle time')
)
INSERT INTO equipment_sensors(sensor_code,asset_id,sensor_type,engineering_unit,functional_class,description)
SELECT d.asset_code||'_'||d.suffix,a.asset_id,d.sensor_type,d.unit,d.functional_class,d.description
FROM definitions d JOIN assets a USING(asset_code)
ON CONFLICT (sensor_code) DO NOTHING;

-- Planned changeover owns its own interval inside Scheduled Production. It reduces
-- Availability under this convention but is excluded from unscheduled Stop Loss.
WITH base AS (
 SELECT epr.asset_id,epr.lot_id,pl.planned_start,ps.shift_id,pc.planned_changeover_minutes
 FROM equipment_production_runs epr JOIN production_lots pl USING(lot_id) JOIN production_schedule ps USING(lot_id)
 JOIN production_calendar pc ON pc.production_date=ps.production_date AND pc.shift_id=ps.shift_id AND pc.line_id=ps.line_id
 JOIN assets a USING(asset_id) JOIN production_lines l ON l.line_id=pl.line_id
 WHERE l.line_code='LINE-2' AND a.asset_code IN ('MIXER-201','CONVEYOR-201','FILLER-201','LABELER-201') AND pl.status='COMPLETE'
)
INSERT INTO equipment_state_events(asset_id,lot_id,shift_id,state_code,start_time,end_time,primary_stop_reason_id,
 reason_source,reason_confidence,inferred_stop_reason_id,inferred_reason_source,inferred_reason_confidence,evidence)
SELECT b.asset_id,b.lot_id,b.shift_id,'CHANGEOVER',b.planned_start,b.planned_start+make_interval(mins=>b.planned_changeover_minutes),
 r.stop_reason_id,'SCHEDULE_INFERRED',1.00,r.stop_reason_id,'SCHEDULE_INFERRED',1.00,
 jsonb_build_object('production_schedule_active',true,'changeover_active',true,'planned_stop',true)
FROM base b JOIN stop_reason_definitions r ON r.stop_reason_code='CHANGEOVER' WHERE b.planned_changeover_minutes>0
ON CONFLICT (asset_id,start_time,end_time) DO NOTHING;

-- One unscheduled stopped and one running interval per completed equipment run.
-- Classification uses deterministic precedence and exactly one primary reason.
WITH base AS (
 SELECT epr.*,pl.planned_start,pl.actual_start,pl.product_id,ps.shift_id,pc.planned_changeover_minutes,
        a.asset_code,row_number() OVER(PARTITION BY a.asset_code ORDER BY pl.planned_start) AS rn,
        GREATEST(0,epr.planned_minutes-epr.runtime_minutes) AS stopped_minutes
 FROM equipment_production_runs epr
 JOIN production_lots pl USING(lot_id)
 JOIN production_schedule ps USING(lot_id)
 JOIN production_calendar pc ON pc.production_date=ps.production_date AND pc.shift_id=ps.shift_id AND pc.line_id=ps.line_id
 JOIN assets a USING(asset_id)
 JOIN production_lines l ON l.line_id=pl.line_id
 WHERE l.line_code='LINE-2' AND a.asset_code IN ('MIXER-201','CONVEYOR-201','FILLER-201','LABELER-201') AND pl.status='COMPLETE'
), classified AS (
 SELECT b.*,
   CASE
    WHEN asset_code='FILLER-201' AND ((planned_start::date < DATE '2026-06-01' AND rn%6=0) OR (planned_start::date >= DATE '2026-06-01' AND rn%35=0)) THEN 'PHOTOEYE_FAULT'
    WHEN asset_code='CONVEYOR-201' AND rn%10=0 THEN 'BELT_TRACKING_FAULT'
    WHEN asset_code='CONVEYOR-201' AND rn%7=0 THEN 'PRODUCT_JAM'
    WHEN asset_code='FILLER-201' AND rn%9=0 THEN 'WAITING_DOWNSTREAM'
    WHEN asset_code IN ('FILLER-201','LABELER-201') AND rn%5=0 THEN 'WAITING_UPSTREAM'
    WHEN rn%13=0 THEN 'MATERIAL_SHORTAGE'
    WHEN rn%17=0 THEN 'QUALITY_HOLD'
    WHEN rn%19=0 THEN 'OPERATOR_DELAY'
    ELSE 'UNCLASSIFIED_STOP' END AS reason_code
 FROM base b WHERE stopped_minutes > 0
), linked AS (
 SELECT c.*,d.downtime_event_id,d.work_order_id
 FROM classified c
 LEFT JOIN LATERAL (
   SELECT de.downtime_event_id,de.work_order_id
   FROM downtime_events de
   WHERE de.asset_id=c.asset_id
     AND abs(extract(epoch FROM (de.downtime_start-c.planned_start))) < 14*86400
     AND ((c.reason_code='PHOTOEYE_FAULT' AND de.reason ILIKE '%photoeye%' OR de.reason ILIKE '%sensor%')
       OR (c.reason_code='BELT_TRACKING_FAULT' AND (de.reason ILIKE '%belt%' OR de.reason ILIKE '%roller%')))
   ORDER BY abs(extract(epoch FROM (de.downtime_start-c.planned_start))) LIMIT 1
 ) d ON true
)
INSERT INTO equipment_state_events(asset_id,lot_id,shift_id,state_code,start_time,end_time,primary_stop_reason_id,
 reason_source,reason_confidence,inferred_stop_reason_id,inferred_reason_source,inferred_reason_confidence,
 linked_downtime_event_id,linked_work_order_id,evidence)
SELECT l.asset_id,l.lot_id,l.shift_id,
 CASE WHEN l.reason_code IN ('PHOTOEYE_FAULT','BELT_TRACKING_FAULT') THEN 'FAULTED'
      WHEN l.reason_code='WAITING_UPSTREAM' THEN 'STARVED'
      WHEN l.reason_code='WAITING_DOWNSTREAM' THEN 'BLOCKED' ELSE 'STOPPED' END,
 l.planned_start+make_interval(mins=>l.planned_changeover_minutes),l.planned_start+make_interval(mins=>(l.planned_changeover_minutes+l.stopped_minutes)::int),r.stop_reason_id,
 CASE WHEN l.reason_code IN ('PHOTOEYE_FAULT','BELT_TRACKING_FAULT') THEN 'SENSOR_INFERRED' ELSE 'SYSTEM_RULE' END,
 CASE WHEN l.reason_code IN ('PHOTOEYE_FAULT','BELT_TRACKING_FAULT') THEN .98 WHEN l.reason_code='UNCLASSIFIED_STOP' THEN .40 ELSE .90 END,
 r.stop_reason_id,CASE WHEN l.reason_code IN ('PHOTOEYE_FAULT','BELT_TRACKING_FAULT') THEN 'SENSOR_INFERRED' ELSE 'SYSTEM_RULE' END,
 CASE WHEN l.reason_code IN ('PHOTOEYE_FAULT','BELT_TRACKING_FAULT') THEN .98 WHEN l.reason_code='UNCLASSIFIED_STOP' THEN .40 ELSE .90 END,
 l.downtime_event_id,l.work_order_id,
 jsonb_build_object('scheduled_production',true,'run_request',true,'asset_running',false,
   'asset_fault',l.reason_code IN ('PHOTOEYE_FAULT','BELT_TRACKING_FAULT'),
   'photoeye_fault',l.reason_code='PHOTOEYE_FAULT','belt_tracking_fault',l.reason_code='BELT_TRACKING_FAULT',
   'classification_precedence','calendar>planned>safety>fault>jam>downstream>upstream>material/quality/operator>unclassified')
FROM linked l JOIN stop_reason_definitions r ON r.stop_reason_code=l.reason_code
ON CONFLICT (asset_id,start_time,end_time) DO NOTHING;

WITH base AS (
 SELECT epr.*,pl.planned_start,ps.shift_id,a.asset_code,pc.planned_changeover_minutes,
        GREATEST(0,epr.planned_minutes-epr.runtime_minutes) stopped_minutes
 FROM equipment_production_runs epr JOIN production_lots pl USING(lot_id) JOIN production_schedule ps USING(lot_id)
 JOIN production_calendar pc ON pc.production_date=ps.production_date AND pc.shift_id=ps.shift_id AND pc.line_id=ps.line_id
 JOIN assets a USING(asset_id) JOIN production_lines l ON l.line_id=pl.line_id
 WHERE l.line_code='LINE-2' AND a.asset_code IN ('MIXER-201','CONVEYOR-201','FILLER-201','LABELER-201') AND pl.status='COMPLETE'
)
INSERT INTO equipment_state_events(asset_id,lot_id,shift_id,state_code,start_time,end_time,reason_source,reason_confidence,evidence)
SELECT asset_id,lot_id,shift_id,'RUNNING',planned_start+make_interval(mins=>(planned_changeover_minutes+stopped_minutes)::int),
 planned_start+make_interval(mins=>(planned_minutes+planned_changeover_minutes)::int),NULL,NULL,jsonb_build_object('asset_running',true,'synthetic_source','equipment_production_runs')
FROM base WHERE runtime_minutes>0
ON CONFLICT (asset_id,start_time,end_time) DO NOTHING;

-- Generate compact event/periodic observations from each state change. Counter and
-- rate inputs come from the existing deterministic production-run record for the lot.
INSERT INTO sensor_readings(sensor_id,observed_at,numeric_value,discrete_value,quality_status,lot_id,shift_id,source_event_id)
SELECT s.sensor_id,e.start_time,
 CASE s.functional_class
  WHEN 'TOTAL_COUNT' THEN pr.total_count
  WHEN 'GOOD_COUNT' THEN pr.good_count
  WHEN 'REJECT_COUNT' THEN pr.reject_count
  WHEN 'ACTUAL_RATE' THEN CASE WHEN e.state_code='RUNNING' THEN round(pr.total_count/NULLIF(pr.runtime_minutes,0),4) ELSE 0 END
  WHEN 'CYCLE_TIME' THEN CASE WHEN e.state_code='RUNNING' THEN round(60.0*pr.runtime_minutes/NULLIF(pr.total_count,0),4) ELSE 0 END
  WHEN 'BATCH_COUNT' THEN round(pr.total_count/NULLIF(p.default_batch_size,0),2)
  WHEN 'BATCH_CYCLE_TIME' THEN round(pr.runtime_minutes/NULLIF(pr.total_count/NULLIF(p.default_batch_size,0),0),2)
  WHEN 'MOTOR_CURRENT' THEN CASE WHEN e.state_code='RUNNING' THEN 8.0+(e.state_event_id%9)*0.35 ELSE 0.8 END
  WHEN 'TEMPERATURE' THEN CASE WHEN e.state_code='RUNNING' THEN 72.0+(e.state_event_id%7)*0.4 ELSE 66.0 END
  WHEN 'VIBRATION' THEN 1.4+(e.state_event_id%8)*0.08
  WHEN 'BELT_TRACKING' THEN CASE WHEN r.stop_reason_code='BELT_TRACKING_FAULT' THEN 12.0 ELSE 1.0+(e.state_event_id%5)*0.3 END
  ELSE NULL END,
 CASE s.functional_class
  WHEN 'MACHINE_RUN_STATE' THEN CASE WHEN e.state_code='RUNNING' THEN 'RUNNING' ELSE 'STOPPED' END
  WHEN 'FAULT_STATE' THEN CASE WHEN e.state_code='FAULTED' THEN 'FAULTED' ELSE 'CLEAR' END
  WHEN 'JAM_STATE' THEN CASE WHEN r.stop_reason_code IN ('PRODUCT_JAM','COMMODITY_JAM') THEN 'ACTIVE' ELSE 'CLEAR' END
  WHEN 'PHOTOEYE_STATE' THEN CASE WHEN r.stop_reason_code='PHOTOEYE_FAULT' THEN 'INTERMITTENT' WHEN e.state_code='RUNNING' THEN 'PRODUCT_DETECTED' ELSE 'CLEAR' END
  WHEN 'PHOTOEYE_FAULT' THEN CASE WHEN r.stop_reason_code='PHOTOEYE_FAULT' THEN 'ACTIVE' ELSE 'CLEAR' END
  WHEN 'LABEL_PRESENT_STATE' THEN CASE WHEN e.state_code='RUNNING' THEN 'PRESENT' ELSE 'NO_PRODUCT' END
  ELSE NULL END,
 CASE WHEN r.stop_reason_code='PHOTOEYE_FAULT' AND s.functional_class='PHOTOEYE_STATE' THEN 'UNCERTAIN' ELSE 'GOOD' END,
 e.lot_id,e.shift_id,e.state_event_id
FROM equipment_state_events e
JOIN equipment_sensors s USING(asset_id)
LEFT JOIN equipment_production_runs pr ON pr.asset_id=e.asset_id AND pr.lot_id=e.lot_id
LEFT JOIN production_lots pl ON pl.lot_id=e.lot_id
LEFT JOIN products p ON p.product_id=pl.product_id
LEFT JOIN stop_reason_definitions r ON r.stop_reason_id=e.primary_stop_reason_id
ON CONFLICT (sensor_id,observed_at) DO NOTHING;

COMMIT;
