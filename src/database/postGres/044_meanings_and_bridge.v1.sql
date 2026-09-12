-- The app-facing home for meanings, filled by `npm run pipeline -- meanings:publish`.
--
-- Additive and safe to run against a live database: nothing is dropped and
-- given_name_meaning is untouched, so the app keeps serving what it serves
-- today until the backend is deliberately pointed at these tables. Dropping the
-- old table is a later migration, after that switch.
--
-- Two tables rather than one. The text lives once in meanings; everything that
-- is true of a pairing rather than of the text lives on the bridge. "wisdom"
-- cannot itself be Greek — it is Sophia's meaning that is Greek — and the same
-- text reaches different names from different sources at different confidence.
--
-- language_id is nullable and often null: the Wikipedia scrape records no
-- language, and a meaning traced to a rejected language (the proto-languages)
-- keeps none rather than gaining a wrong one. NULLS NOT DISTINCT so those rows
-- still count as duplicates of each other.

BEGIN;

CREATE TABLE IF NOT EXISTS "meanings" (
  "id" SERIAL PRIMARY KEY,
  "text" TEXT UNIQUE NOT NULL,
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
  "date_updated" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "given_name_meaning_bridge" (
  "id" SERIAL PRIMARY KEY,
  "given_name_id" INT NOT NULL REFERENCES "given_names" ("id"),
  "meaning_id" INT NOT NULL REFERENCES "meanings" ("id"),
  "language_id" INT REFERENCES "languages" ("id"),

  -- Kept so a published row can be traced back to what produced it without
  -- reading the workbench: which source said it, which rule read it, and how
  -- much that rule is trusted.
  "source" TEXT NOT NULL,
  "extraction_method" TEXT NOT NULL,
  "confidence" NUMERIC NOT NULL CHECK (confidence >= 0 AND confidence <= 1),

  "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
  "date_updated" TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE NULLS NOT DISTINCT (
    "given_name_id",
    "meaning_id",
    "language_id",
    "source",
    "extraction_method"
  )
);

CREATE INDEX IF NOT EXISTS "given_name_meaning_bridge_given_name_idx"
  ON "given_name_meaning_bridge" ("given_name_id");

CREATE INDEX IF NOT EXISTS "given_name_meaning_bridge_meaning_idx"
  ON "given_name_meaning_bridge" ("meaning_id");

COMMIT;
