BEGIN;

-- The fixed demo clock moved to 2026-08-28, so lots from earlier schedule
-- windows can no longer remain RUNNING. Close them and retain them as history.
WITH demo_anchor AS (
    SELECT anchor_timestamp
    FROM v_demo_context_active
), finalized AS (
    UPDATE production_lots pl
    SET status = 'COMPLETE',
        actual_end = COALESCE(pl.actual_end, pl.planned_end)
    FROM demo_anchor dc
    WHERE pl.status IN ('RUNNING', 'PAUSED')
      AND pl.planned_end <= dc.anchor_timestamp
    RETURNING pl.lot_id, pl.actual_end
)
INSERT INTO production_lot_events (lot_id, event_type, event_timestamp, notes)
SELECT f.lot_id, 'COMPLETED', f.actual_end,
       'Lot finalized when the fixed demonstration clock advanced beyond its schedule window'
FROM finalized f
WHERE NOT EXISTS (
    SELECT 1
    FROM production_lot_events e
    WHERE e.lot_id = f.lot_id
      AND e.event_type = 'COMPLETED'
);

UPDATE production_schedule ps
SET schedule_status = 'COMPLETED'
FROM production_lots pl
WHERE pl.lot_id = ps.lot_id
  AND pl.status = 'COMPLETE'
  AND ps.schedule_status <> 'COMPLETED';

DO $$
DECLARE
    v_line record;
BEGIN
    FOR v_line IN
        SELECT l.line_code,
               count(*) FILTER (WHERE pl.status = 'RUNNING') AS running_count,
               count(*) FILTER (WHERE pl.status = 'COMPLETE') AS completed_count
        FROM production_lines l
        LEFT JOIN production_lots pl ON pl.line_id = l.line_id
        GROUP BY l.line_code
    LOOP
        IF v_line.running_count <> 1 THEN
            RAISE EXCEPTION '% must have exactly one RUNNING lot; found %',
                v_line.line_code, v_line.running_count;
        END IF;
        IF v_line.completed_count = 0 THEN
            RAISE EXCEPTION '% must retain completed lot history', v_line.line_code;
        END IF;
    END LOOP;
END $$;

COMMIT;
