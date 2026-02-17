CREATE OR REPLACE FUNCTION get_wikipedia_pages_raw_to_parse(returns INT DEFAULT 10)
RETURNS TABLE (
  "id" INT,
  "pageid" INT,
  "infobox_json" JSONB,
  "sections_json" JSONB,
  "categories" TEXT[],
  "text" TEXT,
  "wtf_json" JSONB
)
AS $$
BEGIN
  RETURN QUERY
    SELECT wpr."id", wpr."pageid", wpr."infobox_json", wpr."sections_json", wpr."categories", wpr."text", wpr."wtf_json"
    FROM wikipedia_page_raw as wpr
    WHERE NOT EXISTS (
      SELECT 1 FROM wikipedia_parsing_table as wpt
      WHERE wpt.pageid = wpr.pageid
    )
    LIMIT returns;
END;
$$ LANGUAGE plpgsql;
