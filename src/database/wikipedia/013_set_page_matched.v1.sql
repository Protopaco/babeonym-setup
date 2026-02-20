DROP FUNCTION IF EXISTS set_page_matched(INT);
CREATE OR REPLACE FUNCTION set_page_matched(p_pageid INT)
RETURNS VOID AS $$
BEGIN
    UPDATE wikipedia_page_ids
    SET has_been_matched = TRUE, date_updated = NOW()
    WHERE pageid = p_pageid;
END;
$$ LANGUAGE plpgsql;