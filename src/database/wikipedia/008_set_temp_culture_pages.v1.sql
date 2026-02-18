DROP FUNCTION IF EXISTS set_temp_culture_page(INT, TEXT);

CREATE OR REPLACE FUNCTION set_temp_culture_page(p_pageid INT, p_raw_title TEXT)
RETURNS VOID AS $$
BEGIN
  INSERT INTO temp_culture_pages (pageid, raw_title, date_created)
  VALUES (p_pageid, p_raw_title, NOW())
  ON CONFLICT (pageid) DO NOTHING;
     
END;
$$ LANGUAGE plpgsql;
