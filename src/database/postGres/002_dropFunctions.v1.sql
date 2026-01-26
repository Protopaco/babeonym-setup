DROP FUNCTION IF EXISTS insert_name_occurrences(
  p_year INT,
  p_names TEXT[],
  p_genders TEXT[],
  p_counts INT[]
)