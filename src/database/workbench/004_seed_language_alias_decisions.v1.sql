-- Curation decisions for Wiktionary language tokens that need a judgment.
--
-- Tokens whose text already matches a languages row are mapped automatically by
-- the extraction stage, so this file only carries the two kinds that cannot be:
-- historical forms folded into their modern language, and tokens that are not
-- languages at all.
--
-- Kept as a seed file rather than done by hand so the decisions survive a
-- workbench rebuild. Safe to re-run: rows are created if extraction has not met
-- the token yet, and a decision already recorded is not overwritten.

BEGIN;

-- Historical and regional forms folded into a living language. This is the
-- default from the requirements: the app is for choosing a baby name, not for
-- distinguishing Middle English from Old English.
INSERT INTO wiktionary_language_aliases (alias, language_id, status)
SELECT folded.alias, languages.id, 'mapped'
FROM (VALUES
  ('Ancient Greek',     'Greek'),
  ('Middle English',    'English'),
  ('Old English',       'English'),
  ('Old French',        'French'),
  ('Biblical Hebrew',   'Hebrew'),
  ('Norwegian Bokmål',  'Norwegian'),
  ('Norwegian Nynorsk', 'Norwegian'),
  ('Middle Cornish',    'Cornish')
) AS folded (alias, language_label)
JOIN languages ON languages.label = folded.language_label
ON CONFLICT (alias) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

-- Not languages. Rejection has to be sticky, or every re-run puts them back in
-- the review queue.
INSERT INTO wiktionary_language_aliases (alias, status)
VALUES
  ('Germanic languages', 'rejected'),
  ('Celtic languages', 'rejected'),
  ('the Bible', 'rejected')
ON CONFLICT (alias) DO UPDATE
SET status = 'rejected',
    language_id = NULL,
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

COMMIT;
