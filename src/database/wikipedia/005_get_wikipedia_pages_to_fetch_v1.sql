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
  WHERE hits <= p_max_hits
  ORDER BY hits ASC, date_updated ASC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;