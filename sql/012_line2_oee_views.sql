BEGIN;

-- Milestone 4 views are a replaceable semantic layer. Drop only this milestone's
-- views so additive columns can be introduced safely on repeatable deployments.
DROP VIEW IF EXISTS v_plant_operations_oee_rollup,v_equipment_maintenance_trace,v_line2_equipment_current,
 v_filler201_stop_loss_before_after_rca,v_filler201_stop_loss_detail,v_line2_oee_rollup,v_line2_oee_summary,
 v_line2_oee_daily,v_equipment_time_accounting,v_equipment_loss_summary,v_equipment_oee_summary,
 v_equipment_oee_daily,v_equipment_stop_loss,v_equipment_state_history,v_line2_sensor_latest,v_line2_sensor_history CASCADE;

CREATE OR REPLACE VIEW v_line2_sensor_history AS
SELECT sr.observed_at AS time,a.asset_code,a.name AS asset_name,s.sensor_code,s.sensor_type,
       s.functional_class,s.engineering_unit,sr.numeric_value,sr.discrete_value,sr.quality_status,
       pl.lot_number,sh.shift_code,sr.source_event_id
FROM sensor_readings sr JOIN equipment_sensors s USING(sensor_id) JOIN assets a USING(asset_id)
LEFT JOIN production_lots pl USING(lot_id) LEFT JOIN shifts sh USING(shift_id);

CREATE OR REPLACE VIEW v_line2_sensor_latest AS
SELECT DISTINCT ON (s.sensor_id) a.asset_code,a.name AS asset_name,s.sensor_code,s.sensor_type,
       s.functional_class,s.engineering_unit,sr.observed_at,sr.numeric_value,sr.discrete_value,sr.quality_status
FROM equipment_sensors s JOIN assets a USING(asset_id) JOIN sensor_readings sr USING(sensor_id)
ORDER BY s.sensor_id,sr.observed_at DESC;

CREATE OR REPLACE VIEW v_equipment_state_history AS
SELECT e.state_event_id,a.asset_code,a.name AS asset_name,a.equipment_type,'LINE-2'::text AS line_code,
       pl.lot_number,p.product_code,p.product_name,sh.shift_code,e.state_code,e.start_time,e.end_time,
       round(extract(epoch FROM (e.end_time-e.start_time))/60.0,2) AS duration_minutes,
       r.stop_reason_code AS primary_stop_reason_code,r.display_name AS stop_reason,r.loss_category,
       r.responsible_function,r.planned,r.maintenance_related,e.reason_source,e.reason_confidence,
       ir.stop_reason_code AS originally_inferred_reason,e.inferred_reason_source,e.inferred_reason_confidence,
       e.corrected_at,e.linked_downtime_event_id,e.linked_work_order_id,e.evidence
FROM equipment_state_events e JOIN assets a USING(asset_id)
LEFT JOIN production_lots pl USING(lot_id) LEFT JOIN products p USING(product_id) LEFT JOIN shifts sh USING(shift_id)
LEFT JOIN stop_reason_definitions r ON r.stop_reason_id=e.primary_stop_reason_id
LEFT JOIN stop_reason_definitions ir ON ir.stop_reason_id=e.inferred_stop_reason_id;

CREATE OR REPLACE VIEW v_equipment_stop_loss AS
SELECT e.asset_code,e.asset_name,e.equipment_type,e.line_code,e.start_time::date AS production_date,
       e.shift_code,e.lot_number,e.product_code,e.product_name,e.primary_stop_reason_code,e.stop_reason,
       e.loss_category,e.responsible_function,e.planned,e.maintenance_related,e.reason_source,e.reason_confidence,
       count(*) AS stop_count,round(sum(e.duration_minutes),2) AS stop_loss_minutes,
       round(avg(e.duration_minutes),2) AS average_duration_minutes,
       round(sum(e.duration_minutes * CASE WHEN e.asset_code='MIXER-201' THEN pls.ideal_units_per_minute/pr.default_batch_size ELSE pls.ideal_units_per_minute END),2) AS stop_loss_opportunity_units,
       bool_or(e.linked_downtime_event_id IS NOT NULL) AS linked_to_downtime,
       bool_or(e.linked_work_order_id IS NOT NULL) AS linked_to_work_order
FROM v_equipment_state_history e
LEFT JOIN production_lots pl USING(lot_number) LEFT JOIN products pr ON pr.product_code=e.product_code
LEFT JOIN product_line_standards pls ON pls.product_id=pl.product_id AND pls.line_id=pl.line_id
WHERE e.state_code<>'RUNNING' AND NOT COALESCE(e.planned,false)
GROUP BY e.asset_code,e.asset_name,e.equipment_type,e.line_code,e.start_time::date,e.shift_code,e.lot_number,
 e.product_code,e.product_name,e.primary_stop_reason_code,e.stop_reason,e.loss_category,e.responsible_function,
 e.planned,e.maintenance_related,e.reason_source,e.reason_confidence;

CREATE OR REPLACE VIEW v_equipment_oee_daily AS
WITH runs AS (
 SELECT pl.planned_start::date production_date,a.asset_id,a.asset_code,a.name asset_name,a.equipment_type,
        sum(epr.planned_minutes+pc.planned_changeover_minutes) scheduled_production_minutes,
        sum(epr.runtime_minutes) runtime_minutes,
        sum(CASE WHEN a.equipment_type='MIXER' THEN epr.total_count/p.default_batch_size ELSE epr.total_count END) total_count,
        sum(CASE WHEN a.equipment_type='MIXER' THEN epr.good_count/p.default_batch_size ELSE epr.good_count END) good_count,
        sum(CASE WHEN a.equipment_type='MIXER' THEN epr.reject_count/p.default_batch_size ELSE epr.reject_count END) reject_count,
        sum(epr.runtime_minutes * CASE WHEN a.equipment_type='MIXER' THEN epr.ideal_rate/p.default_batch_size ELSE epr.ideal_rate END) theoretical_runtime_output,
        sum(pc.planned_changeover_minutes) changeover_minutes,
        max(CASE WHEN a.equipment_type='MIXER' THEN 'batches' ELSE 'units' END) count_unit
 FROM equipment_production_runs epr JOIN assets a USING(asset_id) JOIN production_lots pl USING(lot_id)
 JOIN products p USING(product_id) JOIN production_schedule ps USING(lot_id)
 JOIN production_calendar pc ON pc.production_date=ps.production_date AND pc.shift_id=ps.shift_id AND pc.line_id=ps.line_id
 WHERE a.asset_code IN ('MIXER-201','CONVEYOR-201','FILLER-201','LABELER-201') AND pl.status='COMPLETE'
 GROUP BY pl.planned_start::date,a.asset_id,a.asset_code,a.name,a.equipment_type
), stops AS (
 SELECT asset_code,start_time::date production_date,count(*) FILTER(WHERE state_code<>'RUNNING' AND NOT COALESCE(planned,false)) stop_count,
        sum(duration_minutes) FILTER(WHERE state_code<>'RUNNING' AND NOT COALESCE(planned,false)) stop_loss_minutes,
        sum(duration_minutes) FILTER(WHERE maintenance_related AND state_code<>'RUNNING') unplanned_maintenance_loss_minutes
 FROM v_equipment_state_history GROUP BY asset_code,start_time::date
)
SELECT r.production_date,r.asset_id,r.asset_code,r.asset_name,r.equipment_type,r.count_unit,
 1440.0::numeric calendar_minutes,
 round(1440.0-r.scheduled_production_minutes,2) scheduled_downtime_minutes,
 round(r.scheduled_production_minutes,2) scheduled_production_minutes,
 round(r.scheduled_production_minutes-r.runtime_minutes-r.changeover_minutes,2) unscheduled_downtime_minutes,
 round(r.runtime_minutes,2) runtime_minutes,
 round(100*r.scheduled_production_minutes/1440.0,2) utilization_percent,
 round(100*r.runtime_minutes/NULLIF(r.scheduled_production_minutes,0),2) availability_percent,
 round(r.theoretical_runtime_output/NULLIF(r.runtime_minutes,0),4) ideal_rate,
 round(r.theoretical_runtime_output,2) theoretical_runtime_output,round(r.total_count,2) actual_total_count,
 round(100*r.total_count/NULLIF(r.theoretical_runtime_output,0),2) performance_percent,
 round(100*(1-r.total_count/NULLIF(r.theoretical_runtime_output,0)),2) performance_loss_percent,
 round(r.theoretical_runtime_output-r.total_count,2) performance_loss_units,
 round((r.theoretical_runtime_output-r.total_count)/NULLIF(r.theoretical_runtime_output/NULLIF(r.runtime_minutes,0),0),2) performance_loss_equivalent_minutes,
 round(r.good_count,2) good_count,round(r.reject_count,2) reject_count,
 round(100*r.good_count/NULLIF(r.total_count,0),2) quality_percent,
 round(100*(1-r.good_count/NULLIF(r.total_count,0)),2) quality_loss_percent,round(r.reject_count,2) quality_loss_units,
 coalesce(s.stop_count,0) stop_count,round(coalesce(s.stop_loss_minutes,0),2) stop_loss_minutes,
 round(coalesce(s.stop_loss_minutes,0)*(r.theoretical_runtime_output/NULLIF(r.runtime_minutes,0)),2) stop_loss_opportunity_units,
 round(100*coalesce(s.stop_loss_minutes,0)/NULLIF(r.scheduled_production_minutes,0),2) stop_loss_percent,
 round(coalesce(s.unplanned_maintenance_loss_minutes,0),2) unplanned_maintenance_loss_minutes,
 round(100*coalesce(s.unplanned_maintenance_loss_minutes,0)/NULLIF(r.scheduled_production_minutes,0),2) unplanned_maintenance_loss_percent,
 round(100*(r.runtime_minutes/NULLIF(r.scheduled_production_minutes,0))*(r.total_count/NULLIF(r.theoretical_runtime_output,0))*(r.good_count/NULLIF(r.total_count,0)),2) oee_percent,
 r.changeover_minutes
FROM runs r LEFT JOIN stops s USING(asset_code,production_date);

CREATE OR REPLACE VIEW v_equipment_oee_summary AS
SELECT asset_id,asset_code,asset_name,equipment_type,max(count_unit) count_unit,
 sum(calendar_minutes) calendar_minutes,sum(scheduled_downtime_minutes) scheduled_downtime_minutes,
 sum(scheduled_production_minutes) scheduled_production_minutes,sum(unscheduled_downtime_minutes) unscheduled_downtime_minutes,
 sum(runtime_minutes) runtime_minutes,sum(changeover_minutes) changeover_minutes,round(100*sum(scheduled_production_minutes)/sum(calendar_minutes),2) utilization_percent,
 round(100*sum(runtime_minutes)/sum(scheduled_production_minutes),2) availability_percent,
 round(sum(theoretical_runtime_output)/sum(runtime_minutes),4) ideal_rate,sum(theoretical_runtime_output) theoretical_runtime_output,
 sum(actual_total_count) actual_total_count,round(100*sum(actual_total_count)/sum(theoretical_runtime_output),2) performance_percent,
 round(100*(1-sum(actual_total_count)/sum(theoretical_runtime_output)),2) performance_loss_percent,
 sum(theoretical_runtime_output)-sum(actual_total_count) performance_loss_units,
 round((sum(theoretical_runtime_output)-sum(actual_total_count))/(sum(theoretical_runtime_output)/sum(runtime_minutes)),2) performance_loss_equivalent_minutes,
 sum(good_count) good_count,sum(reject_count) reject_count,round(100*sum(good_count)/sum(actual_total_count),2) quality_percent,
 round(100*(1-sum(good_count)/sum(actual_total_count)),2) quality_loss_percent,sum(quality_loss_units) quality_loss_units,
 sum(stop_count) stop_count,sum(stop_loss_minutes) stop_loss_minutes,sum(stop_loss_opportunity_units) stop_loss_opportunity_units,
 round(100*sum(stop_loss_minutes)/sum(scheduled_production_minutes),2) stop_loss_percent,
 sum(unplanned_maintenance_loss_minutes) unplanned_maintenance_loss_minutes,
 round(100*sum(unplanned_maintenance_loss_minutes)/sum(scheduled_production_minutes),2) unplanned_maintenance_loss_percent,
 round(100*(sum(runtime_minutes)/sum(scheduled_production_minutes))*(sum(actual_total_count)/sum(theoretical_runtime_output))*(sum(good_count)/sum(actual_total_count)),2) oee_percent
FROM v_equipment_oee_daily GROUP BY asset_id,asset_code,asset_name,equipment_type ORDER BY asset_code;

CREATE OR REPLACE VIEW v_equipment_loss_summary AS
SELECT asset_code,stop_reason,loss_category,responsible_function,maintenance_related,
 CASE WHEN reason_source IN ('OPERATOR_SELECTED','MAINTENANCE_SELECTED','MANUAL_OVERRIDE') THEN 'MANUAL' ELSE 'AUTOMATIC' END classification_method,
 sum(stop_count) stop_count,round(sum(stop_loss_minutes),2) stop_loss_minutes,round(avg(average_duration_minutes),2) average_duration_minutes,
 round(sum(stop_loss_opportunity_units),2) stop_loss_opportunity_units
FROM v_equipment_stop_loss GROUP BY asset_code,stop_reason,loss_category,responsible_function,maintenance_related,
 CASE WHEN reason_source IN ('OPERATOR_SELECTED','MAINTENANCE_SELECTED','MANUAL_OVERRIDE') THEN 'MANUAL' ELSE 'AUTOMATIC' END;

CREATE OR REPLACE VIEW v_equipment_time_accounting AS SELECT asset_code,calendar_minutes,scheduled_downtime_minutes,scheduled_production_minutes,
 changeover_minutes,unscheduled_downtime_minutes,runtime_minutes,utilization_percent,availability_percent FROM v_equipment_oee_summary;

-- Line OEE is independently calculated from line scheduled time, bottleneck runtime,
-- product-specific ideal rate, and line lot counts. It is never an average of equipment OEE.
CREATE OR REPLACE VIEW v_line2_oee_daily AS
WITH line_runs AS (
 SELECT pl.planned_start::date production_date,pl.lot_id,l.line_id,l.line_code,l.name line_name,
        epr.planned_minutes+pc.planned_changeover_minutes scheduled_minutes,pc.planned_changeover_minutes changeover_minutes,min(epr.runtime_minutes) line_runtime_minutes,
        pls.ideal_units_per_minute,pl.total_quantity,pl.good_quantity,pl.reject_quantity
 FROM production_lots pl JOIN production_lines l USING(line_id) JOIN production_schedule ps USING(lot_id)
 JOIN production_calendar pc ON pc.production_date=ps.production_date AND pc.shift_id=ps.shift_id AND pc.line_id=ps.line_id
 JOIN product_line_standards pls ON pls.product_id=pl.product_id AND pls.line_id=pl.line_id
 JOIN equipment_production_runs epr ON epr.lot_id=pl.lot_id
 JOIN assets a ON a.asset_id=epr.asset_id
 WHERE l.line_code='LINE-2' AND pl.status='COMPLETE' AND a.asset_code IN ('MIXER-201','CONVEYOR-201','FILLER-201','LABELER-201')
 GROUP BY pl.planned_start::date,pl.lot_id,l.line_id,l.line_code,l.name,epr.planned_minutes,pc.planned_changeover_minutes,
          pls.ideal_units_per_minute,pl.total_quantity,pl.good_quantity,pl.reject_quantity
), d AS (
 SELECT production_date,line_id,line_code,line_name,sum(scheduled_minutes) scheduled_production_minutes,
 sum(line_runtime_minutes) runtime_minutes,sum(changeover_minutes) changeover_minutes,sum(line_runtime_minutes*ideal_units_per_minute) theoretical_runtime_output,
 sum(total_quantity) total_count,sum(good_quantity) good_count,sum(reject_quantity) reject_count
 FROM line_runs GROUP BY production_date,line_id,line_code,line_name
)
SELECT production_date,line_id,line_code,line_name,1440.0::numeric calendar_minutes,
 1440.0-scheduled_production_minutes scheduled_downtime_minutes,scheduled_production_minutes,changeover_minutes,
 scheduled_production_minutes-runtime_minutes-changeover_minutes unscheduled_downtime_minutes,runtime_minutes,
 round(100*scheduled_production_minutes/1440.0,2) utilization_percent,
 round(100*runtime_minutes/scheduled_production_minutes,2) availability_percent,
 round(theoretical_runtime_output/runtime_minutes,4) product_weighted_ideal_rate,
 theoretical_runtime_output,total_count,round(100*total_count/theoretical_runtime_output,2) performance_percent,
 round(100*(1-total_count/theoretical_runtime_output),2) performance_loss_percent,theoretical_runtime_output-total_count performance_loss_units,
 round((theoretical_runtime_output-total_count)/(theoretical_runtime_output/runtime_minutes),2) performance_loss_equivalent_minutes,
 good_count,reject_count,round(100*good_count/total_count,2) quality_percent,round(100*(1-good_count/total_count),2) quality_loss_percent,
 reject_count quality_loss_units,scheduled_production_minutes-runtime_minutes-changeover_minutes stop_loss_minutes,
 round((scheduled_production_minutes-runtime_minutes-changeover_minutes)*(theoretical_runtime_output/runtime_minutes),2) stop_loss_opportunity_units,
 round(100*(runtime_minutes/scheduled_production_minutes)*(total_count/theoretical_runtime_output)*(good_count/total_count),2) oee_percent
FROM d;

CREATE OR REPLACE VIEW v_line2_oee_summary AS
SELECT line_id,line_code,line_name,sum(calendar_minutes) calendar_minutes,sum(scheduled_downtime_minutes) scheduled_downtime_minutes,
 sum(scheduled_production_minutes) scheduled_production_minutes,sum(changeover_minutes) changeover_minutes,sum(unscheduled_downtime_minutes) unscheduled_downtime_minutes,
 sum(runtime_minutes) runtime_minutes,round(100*sum(scheduled_production_minutes)/sum(calendar_minutes),2) utilization_percent,
 round(100*sum(runtime_minutes)/sum(scheduled_production_minutes),2) availability_percent,
 round(sum(theoretical_runtime_output)/sum(runtime_minutes),4) product_weighted_ideal_rate,sum(theoretical_runtime_output) theoretical_runtime_output,
 sum(total_count) total_count,round(100*sum(total_count)/sum(theoretical_runtime_output),2) performance_percent,
 round(100*(1-sum(total_count)/sum(theoretical_runtime_output)),2) performance_loss_percent,
 sum(performance_loss_units) performance_loss_units,sum(performance_loss_equivalent_minutes) performance_loss_equivalent_minutes,
 sum(good_count) good_count,sum(reject_count) reject_count,round(100*sum(good_count)/sum(total_count),2) quality_percent,
 round(100*(1-sum(good_count)/sum(total_count)),2) quality_loss_percent,sum(quality_loss_units) quality_loss_units,
 sum(stop_loss_minutes) stop_loss_minutes,sum(stop_loss_opportunity_units) stop_loss_opportunity_units,
 round(100*(sum(runtime_minutes)/sum(scheduled_production_minutes))*(sum(total_count)/sum(theoretical_runtime_output))*(sum(good_count)/sum(total_count)),2) oee_percent
FROM v_line2_oee_daily GROUP BY line_id,line_code,line_name;

CREATE OR REPLACE VIEW v_line2_oee_rollup AS
SELECT 'LINE'::text rollup_level,line_code entity_code,line_name entity_name,utilization_percent,availability_percent,
 performance_percent,quality_percent,oee_percent FROM v_line2_oee_summary
UNION ALL
SELECT 'EQUIPMENT',asset_code,asset_name,utilization_percent,availability_percent,performance_percent,quality_percent,oee_percent
FROM v_equipment_oee_summary;

CREATE OR REPLACE VIEW v_filler201_stop_loss_detail AS
SELECT e.*,d.reason downtime_reason,w.work_order_number,w.title work_order_title,f.failure_mode,
       rca.rca_number,rca.root_cause,ca.action_description,pm.pm_code,pr.revision_number AS pm_revision,pr.change_reason AS pm_revision_reason
FROM v_equipment_state_history e
LEFT JOIN downtime_events d ON d.downtime_event_id=e.linked_downtime_event_id
LEFT JOIN work_orders w ON w.work_order_id=COALESCE(e.linked_work_order_id,d.work_order_id)
LEFT JOIN failure_events f ON f.work_order_id=w.work_order_id
LEFT JOIN rca_events rca ON rca.work_order_id=w.work_order_id
LEFT JOIN corrective_actions ca USING(rca_event_id)
LEFT JOIN pm_plan_revisions pr USING(rca_event_id)
LEFT JOIN pm_plans pm USING(pm_plan_id)
WHERE e.asset_code='FILLER-201' AND e.state_code<>'RUNNING' AND NOT COALESCE(e.planned,false);

CREATE OR REPLACE VIEW v_filler201_stop_loss_before_after_rca AS
SELECT CASE WHEN start_time::date<DATE '2026-06-01' THEN 'PRE_RCA' ELSE 'POST_RCA' END rca_period,
 count(*) stop_count,round(sum(duration_minutes),2) stop_loss_minutes,
 round(sum(duration_minutes) FILTER(WHERE primary_stop_reason_code='PHOTOEYE_FAULT'),2) photoeye_stop_minutes,
 round(avg(duration_minutes),2) average_stop_minutes
FROM v_equipment_state_history WHERE asset_code='FILLER-201' AND state_code<>'RUNNING' AND NOT COALESCE(planned,false) GROUP BY 1;

CREATE OR REPLACE VIEW v_line2_equipment_current AS
SELECT DISTINCT ON (a.asset_code) a.asset_code,a.name asset_name,a.equipment_type,'LINE-2'::text line_code,
 pl.lot_number,p.product_name,sh.shift_code,concat(emp.first_name,' ',emp.last_name) operator_name,
 e.state_code,r.display_name current_fault,e.start_time last_state_change,
 (SELECT max(observed_at) FROM sensor_readings sr JOIN equipment_sensors es USING(sensor_id) WHERE es.asset_id=a.asset_id) last_sensor_update
FROM assets a JOIN equipment_state_events e USING(asset_id) LEFT JOIN stop_reason_definitions r ON r.stop_reason_id=e.primary_stop_reason_id
LEFT JOIN production_lots pl USING(lot_id) LEFT JOIN products p USING(product_id) LEFT JOIN shifts sh USING(shift_id)
LEFT JOIN LATERAL (SELECT employee_id FROM employee_schedules x WHERE x.line_id=pl.line_id AND x.schedule_date=pl.planned_start::date AND x.assigned_role ILIKE '%operator%' LIMIT 1) op ON true
LEFT JOIN employees emp ON emp.employee_id=op.employee_id
WHERE a.asset_code IN ('MIXER-201','CONVEYOR-201','FILLER-201','LABELER-201') ORDER BY a.asset_code,e.end_time DESC;

CREATE OR REPLACE VIEW v_equipment_maintenance_trace AS
SELECT a.asset_code,d.downtime_start,d.downtime_end,d.reason AS downtime_reason,w.work_order_number,w.title AS work_order,
 f.failure_mode,rca.rca_number,rca.root_cause,ca.action_description,pm.pm_code,pr.revision_number AS pm_revision,pr.change_reason
FROM downtime_events d JOIN assets a USING(asset_id) LEFT JOIN work_orders w USING(work_order_id)
LEFT JOIN failure_events f USING(work_order_id) LEFT JOIN rca_events rca USING(work_order_id)
LEFT JOIN corrective_actions ca USING(rca_event_id) LEFT JOIN pm_plan_revisions pr USING(rca_event_id) LEFT JOIN pm_plans pm USING(pm_plan_id)
WHERE a.asset_code IN ('MIXER-201','CONVEYOR-201','FILLER-201','LABELER-201');

-- Plant operations rollup deliberately avoids a false arithmetic-average Plant OEE.
CREATE OR REPLACE VIEW v_plant_operations_oee_rollup AS
SELECT 'Plant Operations Rollup (not Plant OEE)'::text plant_metric,
       (SELECT overall_oee_percent FROM v_line_oee_components WHERE line_code='LINE-1') line1_existing_oee_percent,
       l2.oee_percent line2_oee_percent,l2.total_count line2_total_output,l2.good_count line2_good_output
FROM v_line2_oee_summary l2;

COMMIT;
