\pset pager off
\echo '=== Milestone 4 counts ==='
SELECT (SELECT count(*) FROM stop_reason_definitions) stop_reasons,
       (SELECT count(*) FROM equipment_sensors) sensors,
       (SELECT count(*) FROM sensor_readings) sensor_readings,
       (SELECT count(*) FROM equipment_state_events) state_events;

DO $$
DECLARE missing_views text; avg_machine_oee numeric; line_oee numeric; pre_loss numeric; post_loss numeric;
BEGIN
 IF (SELECT count(DISTINCT asset_id) FROM equipment_sensors) <> 4 THEN RAISE EXCEPTION 'Exactly four Line 2 assets must have sensors'; END IF;
 IF EXISTS (SELECT 1 FROM equipment_sensors s JOIN assets a USING(asset_id) WHERE a.asset_code NOT IN ('MIXER-201','CONVEYOR-201','FILLER-201','LABELER-201')) THEN RAISE EXCEPTION 'Sensor found outside four instrumented assets'; END IF;
 IF EXISTS (SELECT 1 FROM sensor_readings sr JOIN equipment_sensors s USING(sensor_id) JOIN assets a USING(asset_id) WHERE a.asset_code NOT IN ('MIXER-201','CONVEYOR-201','FILLER-201','LABELER-201')) THEN RAISE EXCEPTION 'Reading tied to invalid asset'; END IF;
 IF EXISTS (SELECT 1 FROM equipment_state_events WHERE end_time<=start_time) THEN RAISE EXCEPTION 'Negative/zero state duration'; END IF;
 IF EXISTS (SELECT 1 FROM equipment_state_events a JOIN equipment_state_events b ON a.asset_id=b.asset_id AND a.state_event_id<b.state_event_id AND a.start_time<b.end_time AND a.end_time>b.start_time) THEN RAISE EXCEPTION 'Overlapping state events detected'; END IF;
 IF EXISTS (SELECT 1 FROM v_equipment_oee_summary WHERE abs(calendar_minutes-scheduled_downtime_minutes-scheduled_production_minutes)>.01) THEN RAISE EXCEPTION 'Equipment calendar reconciliation failed'; END IF;
 IF EXISTS (SELECT 1 FROM v_equipment_oee_summary WHERE runtime_minutes>scheduled_production_minutes OR abs(unscheduled_downtime_minutes-(scheduled_production_minutes-changeover_minutes-runtime_minutes))>.01) THEN RAISE EXCEPTION 'Availability time reconciliation failed'; END IF;
 IF EXISTS (SELECT 1 FROM v_equipment_state_history WHERE state_code='CHANGEOVER' AND (primary_stop_reason_code<>'CHANGEOVER' OR NOT planned)) THEN RAISE EXCEPTION 'Changeover classification failed'; END IF;
 IF EXISTS (SELECT 1 FROM v_equipment_oee_summary WHERE good_count+reject_count>actual_total_count+.10) THEN RAISE EXCEPTION 'Equipment count integrity failed'; END IF;
 IF EXISTS (SELECT 1 FROM v_equipment_oee_summary WHERE abs(utilization_percent-100*scheduled_production_minutes/calendar_minutes)>.02) THEN RAISE EXCEPTION 'Utilization formula failed'; END IF;
 IF EXISTS (SELECT 1 FROM v_equipment_oee_summary WHERE abs(oee_percent-(availability_percent*performance_percent*quality_percent/10000))>.05) THEN RAISE EXCEPTION 'Equipment OEE A x P x Q failed'; END IF;
 IF EXISTS (SELECT 1 FROM v_line2_oee_summary WHERE abs(oee_percent-(availability_percent*performance_percent*quality_percent/10000))>.05) THEN RAISE EXCEPTION 'Line OEE A x P x Q failed'; END IF;
 SELECT avg(oee_percent),max((SELECT oee_percent FROM v_line2_oee_summary)) INTO avg_machine_oee,line_oee FROM v_equipment_oee_summary;
 IF abs(line_oee-avg_machine_oee)<.001 THEN RAISE EXCEPTION 'Line OEE unexpectedly equals arithmetic average machine OEE'; END IF;
 IF EXISTS (SELECT 1 FROM v_equipment_oee_summary WHERE asset_code='AIR-COMP-001') THEN RAISE EXCEPTION 'Air-Comp-001 received piece-rate OEE'; END IF;
 IF NOT EXISTS (SELECT 1 FROM v_equipment_state_history WHERE asset_code='FILLER-201' AND primary_stop_reason_code='PHOTOEYE_FAULT') THEN RAISE EXCEPTION 'Filler-201 photoeye stops missing'; END IF;
 IF NOT EXISTS (SELECT 1 FROM v_filler201_stop_loss_detail WHERE primary_stop_reason_code='PHOTOEYE_FAULT' AND linked_downtime_event_id IS NOT NULL AND work_order_number IS NOT NULL) THEN RAISE EXCEPTION 'Filler-201 photoeye chain is not linked to downtime/work order'; END IF;
 SELECT stop_loss_minutes INTO pre_loss FROM v_filler201_stop_loss_before_after_rca WHERE rca_period='PRE_RCA';
 SELECT stop_loss_minutes INTO post_loss FROM v_filler201_stop_loss_before_after_rca WHERE rca_period='POST_RCA';
 IF post_loss>=pre_loss THEN RAISE EXCEPTION 'Filler-201 stop loss did not improve post-RCA'; END IF;
 IF NOT EXISTS (SELECT 1 FROM v_equipment_state_history WHERE asset_code='CONVEYOR-201' AND primary_stop_reason_code='BELT_TRACKING_FAULT') THEN RAISE EXCEPTION 'Conveyor-201 belt tracking events missing'; END IF;
 IF EXISTS (SELECT 1 FROM equipment_state_events WHERE state_code<>'RUNNING' AND primary_stop_reason_id IS NULL) THEN RAISE EXCEPTION 'Stopped interval lacks primary classification'; END IF;

 SELECT string_agg(name,', ') INTO missing_views FROM (VALUES
 ('v_line2_sensor_latest'),('v_line2_sensor_history'),('v_equipment_state_history'),('v_equipment_stop_loss'),
 ('v_equipment_time_accounting'),('v_equipment_oee_daily'),('v_equipment_oee_summary'),('v_equipment_loss_summary'),
 ('v_filler201_stop_loss_detail'),('v_filler201_stop_loss_before_after_rca'),('v_line2_oee_daily'),
 ('v_line2_oee_summary'),('v_line2_oee_rollup'),('v_line2_equipment_current'),('v_equipment_maintenance_trace'),
 ('v_plant_operations_oee_rollup')) required(name) WHERE to_regclass('public.'||name) IS NULL;
 IF missing_views IS NOT NULL THEN RAISE EXCEPTION 'Missing views: %',missing_views; END IF;

 IF EXISTS (
  SELECT asset_code FROM (VALUES
   ('MIXER-201',ARRAY['MACHINE_RUN_STATE','FAULT_STATE','BATCH_COUNT','BATCH_CYCLE_TIME','MOTOR_CURRENT','TEMPERATURE','VIBRATION']),
   ('CONVEYOR-201',ARRAY['MACHINE_RUN_STATE','FAULT_STATE','TOTAL_COUNT','ACTUAL_RATE','JAM_STATE','MOTOR_CURRENT','BELT_TRACKING']),
   ('FILLER-201',ARRAY['MACHINE_RUN_STATE','FAULT_STATE','TOTAL_COUNT','GOOD_COUNT','REJECT_COUNT','ACTUAL_RATE','PHOTOEYE_STATE','PHOTOEYE_FAULT','CYCLE_TIME']),
   ('LABELER-201',ARRAY['MACHINE_RUN_STATE','FAULT_STATE','TOTAL_COUNT','REJECT_COUNT','ACTUAL_RATE','LABEL_PRESENT_STATE','CYCLE_TIME'])
  ) required(asset_code,classes)
  WHERE EXISTS (SELECT 1 FROM unnest(classes) c WHERE NOT EXISTS (SELECT 1 FROM equipment_sensors s JOIN assets a USING(asset_id) WHERE a.asset_code=required.asset_code AND s.functional_class=c))
 ) THEN RAISE EXCEPTION 'Required sensor functional class missing'; END IF;
END $$;

\echo '=== Line 2 independent OEE ==='
SELECT * FROM v_line2_oee_summary;
\echo '=== Line 2 equipment scorecard ==='
SELECT asset_code,utilization_percent,availability_percent,performance_percent,quality_percent,oee_percent FROM v_equipment_oee_summary ORDER BY asset_code;
\echo '=== Filler-201 pre/post RCA stop loss ==='
SELECT * FROM v_filler201_stop_loss_before_after_rca ORDER BY rca_period;
\echo 'MILESTONE 4 VALIDATION PASSED'
