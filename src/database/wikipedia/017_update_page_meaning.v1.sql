DROP FUNCTION IF EXISTS update_page_meaning(INT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION update_page_meaning(p_pageid INT, p_short_meaning TEXT, p_long_meaning TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE page_meanings
  SET short_meaning = p_short_meaning,
      long_meaning = p_long_meaning
  WHERE pageid = p_pageid;
END;
$$ LANGUAGE plpgsql;  