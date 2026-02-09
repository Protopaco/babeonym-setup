DROP FUNCTION IF EXISTS set_wikipedia_page_ids_bulk(jsonb, text);

CREATE OR REPLACE FUNCTION set_wikipedia_page_ids_bulk(p_rows jsonb, p_source text)
RETURNS VOID AS $$
BEGIN
  INSERT INTO wikipedia_page_ids (source, pageid, title, ns)
  SELECT
    p_source,
    (r.value->>'pageid')::int,
    r.value->>'title',
    (r.value->>'ns')::int
  FROM jsonb_array_elements(p_rows) AS r(value)
  ON CONFLICT (pageid) DO UPDATE
  SET
    source = EXCLUDED.source,
    title  = EXCLUDED.title,
    ns     = EXCLUDED.ns,
    date_updated = NOW();
END;
$$ LANGUAGE plpgsql;


