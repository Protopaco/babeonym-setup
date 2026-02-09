DROP FUNCTION IF EXISTS set_wikipedia_pages_raw(jsonb);

CREATE OR REPLACE FUNCTION set_wikipedia_pages_raw(p_rows jsonb)
RETURNS VOID AS $$
BEGIN
  -- Upsert raw content
  INSERT INTO wikipedia_page_raw (pageid, raw_content)
  SELECT
    (r.value->>'pageid')::int,
    r.value->>'raw_content'
  FROM jsonb_array_elements(p_rows) AS r(value)
  ON CONFLICT (pageid) DO UPDATE
  SET
    raw_content = EXCLUDED.raw_content,
    date_updated = NOW();

  -- Increment hits for the same set of pageids
  UPDATE wikipedia_page_ids wpi
  SET
    hits = COALESCE(wpi.hits, 0) + 1,
    date_updated = NOW()
  FROM (
    SELECT DISTINCT (r.value->>'pageid')::int AS pageid
    FROM jsonb_array_elements(p_rows) AS r(value)
  ) x
  WHERE wpi.pageid = x.pageid;

END;
$$ LANGUAGE plpgsql;
