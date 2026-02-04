
DROP FUNCTION IF EXISTS seed_given_custom_name_bridge();

CREATE OR REPLACE FUNCTION seed_given_custom_name_bridge()
RETURNS VOID AS $$
BEGIN
  -- Seed given_custom_name_bridge for given names that do not yet have a bridge  
INSERT INTO given_custom_name_bridge (given_name_id)
SELECT gn.id
FROM given_names gn
LEFT JOIN given_custom_name_bridge b
  ON b.given_name_id = gn.id
WHERE b.id IS NULL;
END;
$$ LANGUAGE plpgsql;