
DROP FUNCTION IF EXISTS get_pages_need_meanings(INT);

CREATE OR REPLACE FUNCTION get_pages_need_meanings(p_limit INT)
RETURNS TABLE (
    out_pageid INT)
AS $$
BEGIN
  RETURN QUERY
  SELECT pageid
  FROM page_meanings
  WHERE short_meaning IS NULL
  AND long_meaning IS NULL
  LIMIT p_limit;

 UPDATE page_meanings
  SET attempts = attempts + 1
  WHERE pageid IN (SELECT pageid FROM page_meanings WHERE short_meaning IS NULL AND long_meaning IS NULL LIMIT p_limit);
END;
$$ LANGUAGE plpgsql;