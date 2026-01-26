CREATE OR REPLACE FUNCTION set_date_updated()
RETURNS trigger AS $$
BEGIN
  NEW.date_updated = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_user_settings_set_date_updated
BEFORE UPDATE ON user_settings
FOR EACH ROW
EXECUTE FUNCTION set_date_updated();


CREATE TRIGGER trg_user_given_names_states_set_date_updated
BEFORE UPDATE ON user_given_names_states
FOR EACH ROW
EXECUTE FUNCTION set_date_updated();

CREATE TRIGGER trg_given_name_ratings_set_date_updated
BEFORE UPDATE ON given_name_ratings
FOR EACH ROW
EXECUTE FUNCTION set_date_updated();