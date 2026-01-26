CREATE OR REPLACE FUNCTION insert_name_occurrences(
  p_year INT,
  p_names TEXT[],
  p_genders TEXT[],
  p_counts INT[]
)
RETURNS VOID AS $$
DECLARE
  v_name TEXT;
  v_gender gender;
  v_count INT;
  v_given_name_id INT;
  v_index INT;
BEGIN
  -- First, ensure all names exist in given_names
  INSERT INTO given_names (given_name, date_created)
  SELECT DISTINCT unnest_name, CURRENT_TIMESTAMP
  FROM unnest(p_names) AS unnest_name
  WHERE NOT EXISTS (
    SELECT 1 FROM given_names WHERE given_name = unnest_name
  );
  
  -- Then insert occurrences in bulk
  FOR v_index IN 1..array_length(p_names, 1) LOOP
    v_name := p_names[v_index];
    v_gender := p_genders[v_index]::gender;
    v_count := p_counts[v_index];
    
    -- Get the given_name_id
    SELECT id INTO v_given_name_id
    FROM given_names
    WHERE given_name = v_name;
    
    -- Insert the occurrence
    INSERT INTO given_name_occurrences (
      given_name_id, year, gender, occurrences, date_created
    ) VALUES (
      v_given_name_id, p_year, v_gender, v_count, CURRENT_TIMESTAMP
    )
    ON CONFLICT (given_name_id, year, gender) DO NOTHING;

  END LOOP;
END;
$$ LANGUAGE plpgsql;
