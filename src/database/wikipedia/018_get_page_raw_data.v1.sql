DROP FUNCTION IF EXISTS get_page_raw_data(INT);

CREATE OR REPLACE FUNCTION get_page_raw_data(p_pageid INT)
RETURNS TABLE (
    out_id INT,
    out_pageid INT,
    out_infobox_json JSONB,
    out_sections_json JSONB,
    out_categories TEXT[],
    out_text TEXT,
    out_wtf_json JSONB,
    out_date_created TIMESTAMP,
    out_date_updated TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        id,
        pageid,
        infobox_json,
        sections_json,
        categories,
        text,
        wtf_json,
        date_created,
        date_updated
    FROM wikipedia_page_raw
    WHERE pageid = p_pageid;
END;
$$ LANGUAGE plpgsql