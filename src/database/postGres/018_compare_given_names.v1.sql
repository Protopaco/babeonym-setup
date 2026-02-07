DROP FUNCTION IF EXISTS compare_given_names(p_user_id INT, p_winner_id INT, p_loser_id INT);

CREATE OR REPLACE FUNCTION compare_given_names(
    p_user_id INT,
    p_winner_id INT,  -- given_custom_name_bridge_id
    p_loser_id  INT   -- given_custom_name_bridge_id
)
RETURNS VOID AS $$
DECLARE
    winner_rating FLOAT;
    loser_rating FLOAT;
    expected_winner FLOAT;
    expected_loser FLOAT;
    k_factor INT := 32;
BEGIN
    -- Ensure rating rows exist (default Elo rating 1000)
    INSERT INTO given_name_ratings (user_id, given_custom_name_bridge_id, vote_total, vote_for, rating)
    VALUES (p_user_id, p_winner_id, 0, 0, 1000.0)
    ON CONFLICT (user_id, given_custom_name_bridge_id) DO NOTHING;

    INSERT INTO given_name_ratings (user_id, given_custom_name_bridge_id, vote_total, vote_for, rating)
    VALUES (p_user_id, p_loser_id, 0, 0, 1000.0)
    ON CONFLICT (user_id, given_custom_name_bridge_id) DO NOTHING;

    -- Get current ratings
    SELECT rating INTO winner_rating
    FROM given_name_ratings
    WHERE user_id = p_user_id AND given_custom_name_bridge_id = p_winner_id;

    SELECT rating INTO loser_rating
    FROM given_name_ratings
    WHERE user_id = p_user_id AND given_custom_name_bridge_id = p_loser_id;

    -- Expected ratings (Elo)
    expected_winner := 1.0 / (1.0 + POWER(10.0, (loser_rating - winner_rating) / 400.0));
    expected_loser  := 1.0 - expected_winner;

    -- Update winner
    UPDATE given_name_ratings
    SET
        vote_total  = vote_total + 1,
        vote_for    = vote_for + 1,
        rating       = rating + k_factor * (1.0 - expected_winner)
    WHERE user_id = p_user_id AND given_custom_name_bridge_id = p_winner_id;

    -- Update loser
    UPDATE given_name_ratings
    SET
        vote_total  = vote_total + 1,
        rating       = rating + k_factor * (0.0 - expected_loser)
    WHERE user_id = p_user_id AND given_custom_name_bridge_id = p_loser_id;
END;
$$ LANGUAGE plpgsql;
