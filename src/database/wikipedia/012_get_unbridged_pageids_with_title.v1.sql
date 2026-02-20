DROP FUNCTION IF EXISTS get_unbridged_pageids_with_title(INT);

CREATE OR REPLACE FUNCTION get_unbridged_pageids_with_title(p_limit INT)
RETURNS TABLE (
"pageid" INT,
"title" TEXT,
"resolved_title" TEXT,
"resolved_pageid" INT
) AS $$
BEGIN 
RETURN QUERY
	SELECT wpi.pageid, wpi.title, wpi.resolved_title, wpi.resolved_pageid
	FROM wikipedia_page_ids as wpi
	WHERE NOT EXISTS (
		SELECT 1 FROM page_given_name_bridge as pgnb
		WHERE pgnb.pageid = wpi.pageid
	)
	AND wpi.title IS NOT NULL
    AND wpi.has_been_matched = FALSE
	LIMIT p_limit;
END;
$$ LANGUAGE plpgsql


