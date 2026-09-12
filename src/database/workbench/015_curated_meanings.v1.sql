-- The curated meanings: what a person should actually see on a name page.
--
-- normalised_meaning_candidates is honest but blunt. Edward arrives as five
-- rows reading "rich", "riches", "wealth", "guard", "ward", everything
-- lowercased, and some rows are fragments of an etymology rather than a
-- meaning. No rule fixes that. Deciding that three of those rows are one sense,
-- and that the sense is written "Wealth", is a judgment.
--
-- This table holds those judgments. It is rebuilt by loading the CSV batches in
-- src/database/data/curated/, which are committed and are the real record of
-- the pass; the table is a queryable copy of them, not the original.

BEGIN;

CREATE TABLE IF NOT EXISTS "curated_meanings" (
  "id" SERIAL PRIMARY KEY,
  "given_name_id" INT NOT NULL REFERENCES "given_names" ("id"),

  -- Empty means the name was curated to nothing: every raw row for it was
  -- junk. That is a decision rather than an absence, and publishing reads it as
  -- one — the name shows no meaning instead of falling back to the raw rows.
  "text" TEXT NOT NULL,

  "language_id" INT REFERENCES "languages" ("id"),

  -- The raw phrases this was condensed from, written out rather than
  -- referenced. normalised_meaning_candidates is truncated and rebuilt with its
  -- ids reset on every normalise run, so a row id cited here would be pointing
  -- at an unrelated meaning within a run or two. The phrases do not rot, read
  -- without a join, and answer the question the citation exists for: whether a
  -- curated line condensed the source or rewrote it.
  --
  -- Separated by | because the normaliser splits its own input on commas and
  -- semicolons, so neither can appear inside a phrase.
  "source_phrases" TEXT NOT NULL CHECK ("source_phrases" <> ''),

  -- Carried from the strongest raw phrase cited, resolved when the batch is
  -- loaded and the citation is still live. Null for a row curated to nothing,
  -- which publishes nothing and so has nothing to be confident about.
  "confidence" NUMERIC CHECK (confidence >= 0 AND confidence <= 1),
  CHECK ("text" = '' OR "confidence" IS NOT NULL),

  "note" TEXT NOT NULL DEFAULT '',

  -- Which batch file the row came from, so a bad judgment can be traced back to
  -- the CSV it has to be corrected in.
  "batch_file" TEXT NOT NULL,

  "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
  "date_updated" TIMESTAMP NOT NULL DEFAULT NOW()
);

-- One curated row per sense per language. Catches a batch that repeats a line,
-- and a later batch that re-curates a name an earlier one already covered —
-- both mistakes rather than merges.
CREATE UNIQUE INDEX IF NOT EXISTS "curated_meanings_unique_idx"
  ON "curated_meanings" ("given_name_id", "text", "language_id")
  NULLS NOT DISTINCT;

CREATE INDEX IF NOT EXISTS "curated_meanings_given_name_idx"
  ON "curated_meanings" ("given_name_id");

COMMIT;
