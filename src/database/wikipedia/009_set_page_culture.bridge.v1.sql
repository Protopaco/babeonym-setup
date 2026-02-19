DROP FUNCTION IF EXISTS set_page_culture_bridge_batch(INT, INT[], TEXT);

CREATE OR REPLACE FUNCTION set_page_culture_bridge_batch(
  p_culture_id INT,
  p_pageids INT[],
  p_source TEXT
)
RETURNS VOID AS $$
BEGIN
  -- If culture is null, do nothing (structural buckets)
  IF p_culture_id IS NULL THEN
    RETURN;
  END IF;

  -- 1. Ensure all pageids exist in wikipedia_page_ids
  INSERT INTO wikipedia_page_ids (pageid, source, title, ns, date_created)
  SELECT 
    pid,
    p_source,    
    NULL,          -- title unknown at this stage
    NULL,          -- namespace unknown
    NOW()
  FROM unnest(p_pageids) AS pid
  ON CONFLICT (pageid) DO NOTHING;

  -- 2. Insert bridge rows
  INSERT INTO page_culture_bridge (pageid, culture_id, date_created)
  SELECT 
    pid,
    p_culture_id,
    NOW()
  FROM unnest(p_pageids) AS pid
  ON CONFLICT (pageid, culture_id) DO NOTHING;

END;
$$ LANGUAGE plpgsql;
