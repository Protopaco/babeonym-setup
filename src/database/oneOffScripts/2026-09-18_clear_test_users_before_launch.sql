-- ONE-OFF, DESTRUCTIVE. Not a migration and not part of the setup: never run it
-- in sequence with postGres/, and never run it twice.
--
-- Clears every user from production before launch (ticket [123]), so that
-- usage totals count only real use. Test accounts are cheap to recreate, so none
-- are kept. Deletes all of:
--
--   users                     every user, anonymous and signed in
--   user_settings             theme and surname
--   user_given_names_states   every approve, reject and snooze (action history
--                             and action counts are read from here)
--   given_name_ratings        every vote
--   custom_given_names        names users typed in themselves
--   given_custom_name_bridge  the rows for those custom names only; the rows for
--                             canonical names stay
--   user_sessions             every session, so everyone starts fresh
--
-- Names, popularity, meanings, languages, cultures and all other reference data
-- are untouched. Same tables and order as delete_user (016).
--
-- Deploy the backend's stale-session fix (app.ts, deserializeUser) first, or
-- every returning browser gets a 500 instead of a fresh session.
--
-- DRY RUN BY DEFAULT: it ends in ROLLBACK, so a run only prints what it would
-- do. Check the counts, change ROLLBACK to COMMIT at the bottom, run it again.
--
--   psql "$PROD_DB_PUBLIC_URL" -v ON_ERROR_STOP=1 -f 2026-09-18_clear_test_users_before_launch.sql

BEGIN;

SELECT
  (SELECT count(*) FROM users) AS users_before,
  (SELECT count(*) FROM custom_given_names) AS custom_names_before,
  (SELECT count(*) FROM user_given_names_states) AS actions_before,
  (SELECT count(*) FROM given_name_ratings) AS votes_before,
  (SELECT count(*) FROM user_sessions) AS sessions_before;

DELETE FROM user_given_names_states;

DELETE FROM given_name_ratings;

-- Only the custom-name rows. The canonical-name rows are the name set itself.
DELETE FROM given_custom_name_bridge
WHERE custom_given_name_id IS NOT NULL;

DELETE FROM custom_given_names;

DELETE FROM user_settings;

DELETE FROM users;

DELETE FROM user_sessions;

SELECT
  (SELECT count(*) FROM users) AS users_after,
  (SELECT count(*) FROM custom_given_names) AS custom_names_after,
  (SELECT count(*) FROM user_given_names_states) AS actions_after,
  (SELECT count(*) FROM given_name_ratings) AS votes_after,
  (SELECT count(*) FROM user_sessions) AS sessions_after,
  (SELECT count(*) FROM given_custom_name_bridge) AS canonical_name_rows_after;

-- Change to COMMIT once the dry run's counts look right.
ROLLBACK;
