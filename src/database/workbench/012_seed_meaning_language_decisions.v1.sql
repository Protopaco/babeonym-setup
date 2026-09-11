-- Decisions for the languages found behind meanings: the source language a
-- derivation template names for its gloss, read through Wiktionary's code
-- table. None had been written in a from= field, so the origin review in 005,
-- 009, 010 and 011 never saw them. Reviewed 2026-09-11.
--
-- The rules are 011's:
--
--   A real language gets a row, however few meanings it carries (added by 042).
--   A historical or regional form folds into its language.
--   Proto-languages are rejected, as in 011. A meaning traced to one keeps no
--     language rather than gaining a row for a reconstruction.
--
-- The judgment calls:
--
--   Transalpine Gaulish folds into Gaulish as a regional form.
--   Middle Low German and German Low German fold into German, following Low
--     German.
--   Old Frisian folds into West Frisian, following Frisian in 011.
--   Cantonese folds into Chinese, following Mandarin and Hokkien in 011.
--   Anglo-Norman folds into Norman, following the decision already made for its
--     Wikidata item.
--   Chinook Jargon folds into Chinook. The Chinook row holds one name, Sahalie,
--     and Sahalie comes from Chinook Jargon.
--   Undetermined is Wiktionary's code for an unknown source, not a language.
--
-- Eight tokens need no judgment because they already match a row exactly. They
-- are recorded anyway: the alias refresh only registers tokens from origin
-- claims, so nothing else would map them.
--
-- Depends on 042_seed_meaning_languages.v1.sql having run, since the mappings
-- join languages on label. Wiktionary tokens are keyed on their text, following
-- 005, 009, 010 and 011. Safe to re-run: a decision already recorded is not
-- overwritten.

BEGIN;

-- Languages added by 042, and a regional form folded into one. 24 Wiktionary tokens.
INSERT INTO wiktionary_language_aliases (alias, language_id, status)
SELECT decided.alias, languages.id, 'mapped'
FROM (VALUES
  ('Akkadian',                'Akkadian'),
  ('Bambara',                 'Bambara'),
  ('Caddo',                   'Caddo'),
  ('Central Atlas Tamazight', 'Central Atlas Tamazight'),
  ('Cumbric',                 'Cumbric'),
  ('East Circassian',         'East Circassian'),
  ('Evenki',                  'Evenki'),
  ('Gaulish',                 'Gaulish'),
  ('Transalpine Gaulish',     'Gaulish'),
  ('Hittite',                 'Hittite'),
  ('Kanuri',                  'Kanuri'),
  ('O''odham',                'O''odham'),
  ('Old Church Slavonic',     'Old Church Slavonic'),
  ('Old East Slavic',         'Old East Slavic'),
  ('Pictish',                 'Pictish'),
  ('Shawnee',                 'Shawnee'),
  ('Sudovian',                'Sudovian'),
  ('Sumerian',                'Sumerian'),
  ('Tarifit',                 'Tarifit'),
  ('Venetic',                 'Venetic'),
  ('Yami',                    'Yami'),
  ('Yana',                    'Yana'),
  ('Yucatec Maya',            'Yucatec Maya'),
  ('Zapotec',                 'Zapotec')
) AS decided (alias, language_label)
JOIN languages ON languages.label = decided.language_label
ON CONFLICT (alias) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

-- Names that already match a language carried. 8 Wiktionary tokens.
INSERT INTO wiktionary_language_aliases (alias, language_id, status)
SELECT decided.alias, languages.id, 'mapped'
FROM (VALUES
  ('Aragonese',  'Aragonese'),
  ('Dothraki',   'Dothraki'),
  ('Gujarati',   'Gujarati'),
  ('Karelian',   'Karelian'),
  ('Lakota',     'Lakota'),
  ('Macedonian', 'Macedonian'),
  ('Phoenician', 'Phoenician'),
  ('Tahitian',   'Tahitian')
) AS decided (alias, language_label)
JOIN languages ON languages.label = decided.language_label
ON CONFLICT (alias) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

-- Forms folded into a language already carried. 14 Wiktionary tokens.
INSERT INTO wiktionary_language_aliases (alias, language_id, status)
SELECT decided.alias, languages.id, 'mapped'
FROM (VALUES
  ('Hatran Aramaic',       'Aramaic'),
  ('Old Armenian',         'Armenian'),
  ('Cantonese',            'Chinese'),
  ('Chinook Jargon',       'Chinook'),
  ('German Low German',    'German'),
  ('Middle Low German',    'German'),
  ('Byzantine Greek',      'Greek'),
  ('Ecclesiastical Latin', 'Latin'),
  ('Old Latin',            'Latin'),
  ('Vulgar Latin',         'Latin'),
  ('Old Lithuanian',       'Lithuanian'),
  ('Anglo-Norman',         'Norman'),
  ('Middle Persian',       'Persian'),
  ('Old Frisian',          'West Frisian')
) AS decided (alias, language_label)
JOIN languages ON languages.label = decided.language_label
ON CONFLICT (alias) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

-- Proto-languages, and the code for an unknown source. 13 Wiktionary tokens.
INSERT INTO wiktionary_language_aliases (alias, status)
VALUES
  ('Proto-Balto-Slavic', 'rejected'),
  ('Proto-Finnic', 'rejected'),
  ('Proto-Indo-European', 'rejected'),
  ('Proto-Indo-Iranian', 'rejected'),
  ('Proto-Iranian', 'rejected'),
  ('Proto-Italic', 'rejected'),
  ('Proto-Norse', 'rejected'),
  ('Proto-Samic', 'rejected'),
  ('Proto-Semitic', 'rejected'),
  ('Proto-Siouan', 'rejected'),
  ('Proto-Slavic', 'rejected'),
  ('Proto-West Germanic', 'rejected'),
  ('Undetermined', 'rejected')
ON CONFLICT (alias) DO UPDATE
SET status = 'rejected',
    language_id = NULL,
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

COMMIT;
