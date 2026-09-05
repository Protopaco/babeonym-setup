-- Rewrites a user's ratings so they match an order the user arranged by hand.
--
-- The list is sorted by rating, so a manual reorder has to be expressed as
-- ratings. Rather than nudge the moved name, every name in the submitted order
-- is respaced onto an evenly spaced ladder. That is the only rule that always
-- works: a new user has never compared anything, so every rating is the 1000
-- default and there is no midpoint between neighbours to insert into.
--
-- The gap is fixed at 64 rather than derived from the user's current spread.
-- Elo with k = 32 swings two close names about 32 points apart per vote, so a
-- gap of 64 means a placement survives a stray vote and is undone by three or
-- four deliberate ones. Deriving the gap from the existing range instead would
-- make stickiness depend on how much a user happens to have voted, which is a
-- difference they could not perceive or predict.
--
-- Centred on 1000 rather than counting down from it, because a name added later
-- has no rating row and get_approved_given_names reads it as 1000. Centred, a
-- new name lands mid-list; counting down, it would land above a list the user
-- just arranged by hand.
--
-- Ratings are absolute, not relative, so running this twice with the same order
-- is a no-op rather than something that drifts.

DROP FUNCTION IF EXISTS set_given_name_order(p_user_id INT, p_bridge_ids INT[]);

CREATE OR REPLACE FUNCTION set_given_name_order(
    p_user_id INT,
    p_bridge_ids INT[]
)
RETURNS VOID AS $$
DECLARE
  v_gap CONSTANT NUMERIC := 64;
  v_centre CONSTANT NUMERIC := 1000;
  v_count INT := COALESCE(array_length(p_bridge_ids, 1), 0);
BEGIN
  IF v_count = 0 THEN
    RETURN;
  END IF;

  -- Every submitted id has to be a name this user actually holds. Without this
  -- the array is an arbitrary list of bridge ids and the function would happily
  -- write ratings for names belonging to someone else.
  IF EXISTS (
    SELECT 1
    FROM unnest(p_bridge_ids) AS submitted(bridge_id)
    WHERE NOT EXISTS (
      SELECT 1
      FROM user_given_names_states ugns
      WHERE ugns.user_id = p_user_id
        AND ugns.given_custom_name_bridge_id = submitted.bridge_id
        AND ugns.state = 'approved'
    )
  ) THEN
    RAISE EXCEPTION 'Order contains a name the user has not approved';
  END IF;

  -- Upserted rather than updated: a name that has never been through Compare
  -- Names has no given_name_ratings row at all.
  INSERT INTO given_name_ratings (
    user_id,
    given_custom_name_bridge_id,
    rating,
    date_updated
  )
  SELECT
    p_user_id,
    ordered.bridge_id,
    v_centre + ((v_count - 1)::numeric / 2 - (ordered.position - 1)) * v_gap,
    NOW()
  FROM unnest(p_bridge_ids) WITH ORDINALITY AS ordered(bridge_id, position)
  ON CONFLICT (user_id, given_custom_name_bridge_id)
  DO UPDATE SET
    rating = EXCLUDED.rating,
    date_updated = NOW();

END;
$$ LANGUAGE plpgsql;
