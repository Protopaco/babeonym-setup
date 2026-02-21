INSERT INTO page_meanings (pageid)
SELECT DISTINCT pageid
FROM page_given_name_bridge
ON CONFLICT (pageid) DO NOTHING;
