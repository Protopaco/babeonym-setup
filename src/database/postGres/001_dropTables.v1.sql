-- Drop tables (order matters due to FKs)
DROP TABLE IF EXISTS user_settings CASCADE;
DROP TABLE IF EXISTS user_given_names_states CASCADE;
DROP TABLE IF EXISTS given_name_ratings CASCADE;
DROP TABLE IF EXISTS given_name_popularity_by_decade CASCADE;
DROP TABLE IF EXISTS given_name_occurrences CASCADE;
DROP TABLE IF EXISTS given_name_etymology CASCADE;
DROP TABLE IF EXISTS given_custom_name_bridge CASCADE;
DROP TABLE IF EXISTS custom_given_names CASCADE;
DROP TABLE IF EXISTS given_names CASCADE;
DROP TABLE IF EXISTS decades CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS languages CASCADE;
DROP TABLE IF EXISTS culture_region_bridge CASCADE;
DROP TABLE IF EXISTS language_region_bridge CASCADE;
DROP TABLE IF EXISTS regions CASCADE;
DROP TABLE IF EXISTS culture_region_bridge CASCADE;
DROP TABLE IF EXISTS given_name_meaning CASCADE;
DROP TABLE IF EXISTS cultures CASCADE;
DROP TABLE IF EXISTS user_sessions CASCADE;

-- Drop custom types
DROP TYPE IF EXISTS given_name_state CASCADE;
DROP TYPE IF EXISTS gender CASCADE;
DROP TYPE IF EXISTS auth_provider CASCADE;
DROP TYPE IF EXISTS theme CASCADE;