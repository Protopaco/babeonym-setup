DROP FUNCTION IF EXISTS get_temp_culture_category_by_pageid(p_page_id INT);

CREATE OR REPLACE FUNCTION get_temp_culture_category_by_pageid(p_page_id INT)
RETURNS TABLE (
    raw_title TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        tcp.raw_title AS raw_title
    FROM temp_culture_pages tcp
    WHERE tcp.pageid = p_page_id;
END;
$$ LANGUAGE plpgsql;
