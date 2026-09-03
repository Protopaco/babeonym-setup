CREATE OR REPLACE FUNCTION get_user_action_count(p_user_id INT)
RETURNS TABLE (
  out_action_count INT
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Names ever acted on plus comparisons ever voted on. Both are monotonic:
  -- given_name_action only flips state on an existing row and nothing deletes,
  -- and vote_total is only ever incremented. A comparison increments vote_total
  -- on both of its names, so the summed total is halved.
  RETURN QUERY
  SELECT (
    (
      SELECT COUNT(*)
      FROM user_given_names_states ugns
      WHERE ugns.user_id = p_user_id
    )
    +
    (
      SELECT COALESCE(SUM(gnr.vote_total), 0) / 2
      FROM given_name_ratings gnr
      WHERE gnr.user_id = p_user_id
    )
  )::INT AS out_action_count;
END;
$$;
