-- Decisions for the last languages found behind meanings, continuing 012.
-- Reviewed 2026-09-11.
--
--   Dyula and Mandinka map to their own rows, added by 043.
--   Western Mari folds into Mari, added by 043, as one of its two written
--     standards — following Upper Sorbian into Sorbian in 011.
--   Shelta needs no judgment: it already matches a row, mapped earlier for its
--     Wikidata item.
--   Proto-Albanian is rejected, as every proto-language is.
--
-- Depends on 043_seed_meaning_remainder_languages.v1.sql having run, since the
-- mappings join languages on label. Safe to re-run: a decision already recorded
-- is not overwritten.

BEGIN;

-- Languages added by 043, and a written standard folded into one. 3 Wiktionary tokens.
INSERT INTO wiktionary_language_aliases (alias, language_id, status)
SELECT decided.alias, languages.id, 'mapped'
FROM (VALUES
  ('Dyula',        'Dyula'),
  ('Mandinka',     'Mandinka'),
  ('Western Mari', 'Mari')
) AS decided (alias, language_label)
JOIN languages ON languages.label = decided.language_label
ON CONFLICT (alias) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

-- Names that already match a language carried. 1 Wiktionary token.
INSERT INTO wiktionary_language_aliases (alias, language_id, status)
SELECT decided.alias, languages.id, 'mapped'
FROM (VALUES
  ('Shelta', 'Shelta')
) AS decided (alias, language_label)
JOIN languages ON languages.label = decided.language_label
ON CONFLICT (alias) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

-- Proto-languages. 1 Wiktionary token.
INSERT INTO wiktionary_language_aliases (alias, status)
VALUES
  ('Proto-Albanian', 'rejected')
ON CONFLICT (alias) DO UPDATE
SET status = 'rejected',
    language_id = NULL,
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

COMMIT;
