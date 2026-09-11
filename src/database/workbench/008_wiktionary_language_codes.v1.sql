-- Wiktionary's own table of language codes and the names it gives them.
--
-- Some given-name entries write their origin as a code and a term rather than a
-- language name: {{given name|de|female|from=de:Elisabeth}} means "from the
-- German name Elisabeth". Without this table the code is unreadable, and the
-- whole string ends up in the review queue as if it were a language.
--
-- The names here are Wiktionary's canonical names, which are the same strings a
-- section heading or a plain from= value uses — Ancient Greek, Old Norse,
-- Biblical Hebrew. So a code resolves into a name the alias table already holds
-- a decision for, and codes need no review of their own.
--
-- Filled by wiktionary:refresh-language-codes from the two published modules,
-- and stored rather than fetched during extraction, which reads only local data.

BEGIN;

CREATE TABLE IF NOT EXISTS "wiktionary_language_codes" (
  "code" TEXT PRIMARY KEY,
  "canonical_name" TEXT NOT NULL,
  -- Which module the code came from. Etymology-only codes (grc-koi, hbo,
  -- la-lat) live in their own module, and knowing which is which helps when a
  -- name looks wrong.
  "module" TEXT NOT NULL,
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
  "date_updated" TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMIT;
