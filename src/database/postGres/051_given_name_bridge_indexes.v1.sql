-- get_name_filters (050) counts names per culture and per language to apply the
-- floor of 10. Neither bridge table had an index on the column that count filters
-- on, so each option ran a sequential scan over the whole bridge table: 118 scans
-- for cultures and 95 for languages, ~127ms of a 130ms query.
--
-- The same columns are read by get_name_candidates on every culture- or
-- language-filtered call, which was scanning them too.
--
-- Naming follows the meaning bridge indexes in 044. Plain CREATE INDEX rather
-- than CONCURRENTLY: these tables are reference data written only by the seed,
-- and at ~16,500 rows the build is milliseconds.

CREATE INDEX IF NOT EXISTS "given_name_culture_bridge_culture_idx"
  ON "given_name_culture_bridge" ("culture_id");

CREATE INDEX IF NOT EXISTS "given_name_language_bridge_language_idx"
  ON "given_name_language_bridge" ("language_id");
