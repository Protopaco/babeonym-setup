-- Both meaning sources put through one normaliser, so they can be read as a
-- single vocabulary rather than two.
--
-- The comparison that prompted this found the sources barely overlap: 1,005
-- meanings only Wiktionary has, 1,768 only the old Wikipedia scrape has, 363 in
-- both. Merging roughly doubles what either gives alone, but only once they
-- agree on shape — the old data is Title Case with broken quoting and several
-- senses per string, the new data is lowercase and one sense per claim.
--
-- One row per normalised phrase per name, not per source string, because
-- "Girl, Woman" is two meanings rather than one long one.
--
-- Nothing here is app-facing. Round one still publishes nothing; this is for
-- reading before the meanings table and its bridge are designed for real.

BEGIN;

CREATE TABLE IF NOT EXISTS "normalised_meaning_candidates" (
  "id" SERIAL PRIMARY KEY,
  "given_name_id" INT NOT NULL REFERENCES "given_names" ("id"),
  "text" TEXT NOT NULL,

  -- Nullable and unpopulated for now. The language a meaning derives from is
  -- the second positional argument of the derivation template — "hbo" in
  -- {{der|en|hbo|מִיכָאֵל|lit=who is like God?}} — not the page section the
  -- template sits under, which is English. That code is inside the stored raw
  -- template but was never extracted as a field, and it would need a code to
  -- language mapping of its own. The old Wikipedia data carries no language
  -- attribution at all. Populating this is a follow-up, and guessing it from
  -- the section would put the wrong language on the display line.
  "language_id" INT REFERENCES "languages" ("id"),

  "source" TEXT NOT NULL,
  "extraction_method" TEXT NOT NULL,
  "confidence" NUMERIC NOT NULL CHECK (confidence >= 0 AND confidence <= 1),

  -- What the phrase was cut from, kept so the normaliser can be audited from
  -- its own output: when a row looks wrong it is immediately clear whether a
  -- rule mangled it or the source was already bad.
  "original_text" TEXT NOT NULL,

  "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
  "date_updated" TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE ("given_name_id", "text", "source", "extraction_method")
);

CREATE INDEX IF NOT EXISTS "normalised_meaning_candidates_text_idx"
  ON "normalised_meaning_candidates" ("text");

CREATE INDEX IF NOT EXISTS "normalised_meaning_candidates_given_name_idx"
  ON "normalised_meaning_candidates" ("given_name_id");

COMMIT;
