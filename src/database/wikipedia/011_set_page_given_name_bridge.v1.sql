DROP FUNCTION IF EXISTS set_page_given_name_bridge(INT, INT);
CREATE OR REPLACE FUNCTION set_page_given_name_bridge(p_pageid INT, p_given_name_id INT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO page_given_name_bridge (pageid, given_name_id, date_created)
    VALUES (p_pageid, p_given_name_id, NOW());

    UPDATE wikipedia_page_ids
    SET has_been_matched = TRUE, date_updated = NOW()
    WHERE pageid = p_pageid;
END;
$$ LANGUAGE plpgsql;
