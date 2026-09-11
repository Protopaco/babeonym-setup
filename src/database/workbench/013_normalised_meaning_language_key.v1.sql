-- Puts language_id into the unique key of normalised_meaning_candidates, now
-- that the normaliser fills it. The same phrase can reach a name in more than
-- one language — a gloss given for a Latin form and again for a Greek one — and
-- under the old key the second was discarded as a duplicate, keeping whichever
-- happened to be written first.
--
-- NULLS NOT DISTINCT because most rows have no language: every Wikipedia
-- phrase, and every Wiktionary phrase whose language was rejected or has no
-- decision. Without it, two identical phrases with no language would stop
-- counting as duplicates.
--
-- 006 still describes language_id as unpopulated. This file supersedes that
-- comment. Safe to re-run.

BEGIN;

ALTER TABLE "normalised_meaning_candidates"
  DROP CONSTRAINT IF EXISTS "normalised_meaning_candidates_given_name_id_text_source_ext_key";

CREATE UNIQUE INDEX IF NOT EXISTS "normalised_meaning_candidates_unique_idx"
  ON "normalised_meaning_candidates" (
    "given_name_id",
    "text",
    "source",
    "extraction_method",
    "language_id"
  )
  NULLS NOT DISTINCT;

COMMIT;
