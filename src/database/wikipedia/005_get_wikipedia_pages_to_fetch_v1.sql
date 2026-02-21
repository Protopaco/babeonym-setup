DROP FUNCTION IF EXISTS get_wikipedia_pages_to_fetch(INT, INT);

CREATE OR REPLACE FUNCTION get_wikipedia_pages_to_fetch(p_limit INT DEFAULT 20, p_max_hits INT DEFAULT 1)  
RETURNS TABLE (
    out_pageid INT
)
AS $$
BEGIN
  RETURN QUERY
  SELECT pageid
  FROM wikipedia_page_ids
    WHERE EXISTS (
      SELECT 1 FROM page_given_name_bridge as pgnb
      WHERE pgnb.pageid = wikipedia_page_ids.pageid
    )
    AND NOT EXISTS (
      SELECT 1 FROM wikipedia_page_raw as wpr
      WHERE wpr.pageid = wikipedia_page_ids.pageid
    )
  ORDER BY hits ASC, date_updated ASC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;