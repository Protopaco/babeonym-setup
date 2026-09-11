-- Historical, middle and regional forms in the review tail, folded into the
-- language they are a form of. Reviewed 2026-09-11.
--
-- The rule is the one 004, 005 and 007 already applied case by case — Old
-- English to English, Brazilian Portuguese to Portuguese — adopted here as a
-- rule so the tail did not need 104 separate decisions. It covers old and middle
-- stages (Middle French, Old Persian, Koine Greek), regional varieties (Swiss
-- German, Mexican Spanish, Belgian Dutch) and a few tokens that are simply the
-- language written awkwardly (ultimately from Hebrew).
--
-- Where a token names two reference languages the base is the one named last,
-- which is the head of the phrase: Latin American Spanish is Spanish, not Latin,
-- and Welsh English is English. Matching on the first name found is what got
-- both of those wrong.
--
-- Written as an explicit list rather than as a matching rule inside the SQL, so
-- every fold can be read and questioned. Tokens that arrive later from new
-- sources come back through review instead of being folded unseen.
--
-- Wiktionary tokens are keyed on their text and Wikidata items on their
-- identifier, following 005 and 007. Safe to re-run: a decision already
-- recorded is not overwritten.

BEGIN;

-- 30 Wiktionary tokens.
INSERT INTO wiktionary_language_aliases (alias, language_id, status)
SELECT folded.alias, languages.id, 'mapped'
FROM (VALUES
  ('Old Breton',             'Breton'),
  ('Old Danish',             'Danish'),
  ('Middle Dutch',           'Dutch'),
  ('Old Dutch',              'Dutch'),
  ('Middle French',          'French'),
  ('Alemannic German',       'German'),
  ('East Central German',    'German'),
  ('Low German',             'German'),
  ('Middle High German',     'German'),
  ('Koine Greek',            'Greek'),
  ('Hebrew (פִינְחָס)',      'Hebrew'),
  ('biblical Hebrew',        'Hebrew'),
  ('ultimately from Hebrew', 'Hebrew'),
  ('Middle Irish',           'Irish'),
  ('Old Javanese',           'Javanese'),
  ('Northern Kurdish',       'Kurdish'),
  ('Late Latin',             'Latin'),
  ('Medieval Latin',         'Latin'),
  ('Middle Norwegian',       'Norwegian'),
  ('Old Occitan',            'Occitan'),
  ('Classical Persian',      'Persian'),
  ('Iranian Persian',        'Persian'),
  ('Old Persian',            'Persian'),
  ('Old Polish',             'Polish'),
  ('Old Slovak',             'Slovak'),
  ('Old Spanish',            'Spanish'),
  ('Old Swedish',            'Swedish'),
  ('Ottoman Turkish',        'Turkish'),
  ('Middle Welsh',           'Welsh'),
  ('Old Welsh',              'Welsh')
) AS folded (alias, language_label)
JOIN languages ON languages.label = folded.language_label
ON CONFLICT (alias) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

-- 64 Wikidata items.
INSERT INTO wikidata_language_items (item_qid, item_label, language_id, status)
SELECT folded.item_qid, folded.item_label, languages.id, 'mapped'
FROM (VALUES
  ('Q1194795',   'Maghrebi Arabic',                     'Arabic'),
  ('Q56467',     'Modern Standard Arabic',              'Arabic'),
  ('Q180945',    'Western Armenian',                    'Armenian'),
  ('Q15478520',  'Old Catalan',                         'Catalan'),
  ('Q727694',    'Standard Chinese',                    'Chinese'),
  ('Q1404296',   'Belgian Dutch',                       'Dutch'),
  ('Q34147',     'Flemish Dutch',                       'Dutch'),
  ('Q750939',    'Surinamese Dutch',                    'Dutch'),
  ('Q48767245',  'African American English',            'English'),
  ('Q8002',      'African American Vernacular English', 'English'),
  ('Q44679',     'Australian English',                  'English'),
  ('Q7979',      'British English',                     'English'),
  ('Q44676',     'Canadian English',                    'English'),
  ('Q4567134',   'Caribbean English',                   'English'),
  ('Q1472196',   'Early Modern English',                'English'),
  ('Q665624',    'Hiberno-English',                     'English'),
  ('Q1348800',   'Indian English',                      'English'),
  ('Q36395',     'Middle English',                      'English'),
  ('Q7053766',   'North American English',              'English'),
  ('Q42365',     'Old English',                         'English'),
  ('Q1413694',   'Philippine English',                  'English'),
  ('Q1553250',   'Scottish English',                    'English'),
  ('Q2363292',   'Welsh English',                       'English'),
  ('Q33670660',  'African French',                      'French'),
  ('Q815549',    'Belgian French',                      'French'),
  ('Q102183245', 'Cameroonian French',                  'French'),
  ('Q19871941',  'French language in Algeria',          'French'),
  ('Q17004144',  'Haitian French',                      'French'),
  ('Q35222',     'Old French',                          'French'),
  ('Q65057350',  'American German',                     'German'),
  ('Q306626',    'Austrian German',                     'German'),
  ('Q25433',     'Low German',                          'German'),
  ('Q35218',     'Old High German',                     'German'),
  ('Q387066',    'Swiss German',                        'German'),
  ('Q35497',     'Ancient Greek',                       'Greek'),
  ('Q36510',     'Modern Greek',                        'Greek'),
  ('Q1982248',   'Biblical Hebrew',                     'Hebrew'),
  ('Q8141',      'Modern Hebrew',                       'Hebrew'),
  ('Q35308',     'Old Irish',                           'Irish'),
  ('Q20009724',  'Italian language in Argentina',       'Italian'),
  ('Q20009725',  'Italian language in Brazil',          'Italian'),
  ('Q135292643', 'Italian language in Chile',           'Italian'),
  ('Q6093332',   'Italian language in Venezuela',       'Italian'),
  ('Q36368',     'Kurdish language',                    'Kurdish'),
  ('Q1503113',   'Late Latin',                          'Latin'),
  ('Q1248221',   'Neo-Latin',                           'Latin'),
  ('Q1163234',   'medieval Latin',                      'Latin'),
  ('Q15065',     'Standard Malay',                      'Malay'),
  ('Q35214',     'Anglo-Norman',                        'Norman'),
  ('Q34996',     'Old Norwegian',                       'Norwegian'),
  ('Q10352067',  'Portuguese language in Goa',          'Portuguese'),
  ('Q489811',    'Andalusian Spanish',                  'Spanish'),
  ('Q85146618',  'Argentine Spanish',                   'Spanish'),
  ('Q2631909',   'Castilian Spanish',                   'Spanish'),
  ('Q824909',    'Cuban Spanish',                       'Spanish'),
  ('Q820569',    'Equatoguinean Spanish',               'Spanish'),
  ('Q56649449',  'Latin American Spanish',              'Spanish'),
  ('Q616620',    'Mexican Spanish',                     'Spanish'),
  ('Q1088025',   'Old Spanish',                         'Spanish'),
  ('Q1006465',   'Philippine Spanish',                  'Spanish'),
  ('Q7573411',   'Spanish language in South America',   'Spanish'),
  ('Q3058369',   'Spanish language in the Americas',    'Spanish'),
  ('Q2417210',   'Old Swedish',                         'Swedish'),
  ('Q36730',     'Ottoman Turkish',                     'Turkish')
) AS folded (item_qid, item_label, language_label)
JOIN languages ON languages.label = folded.language_label
ON CONFLICT (item_qid) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wikidata_language_items.status = 'unreviewed';

-- Not covered by the rule. These name several languages at once — Italian or
-- Greek, Persian or Urdu — and an alias can point at only one, so folding would
-- mean choosing a language the source did not choose. One name each. Rejected
-- in the same way as Germanic languages in 004; the claims stay in name_claims.
INSERT INTO wiktionary_language_aliases (alias, status)
VALUES
  ('French and Latin', 'rejected'),
  ('Italian or Greek', 'rejected'),
  ('Latin & Ancient Greek', 'rejected'),
  ('Latin or Hebrew', 'rejected'),
  ('Persian or Urdu', 'rejected'),
  ('Portuguese and Spanish', 'rejected'),
  ('Spanish and Italian', 'rejected'),
  ('Turkish and other languages', 'rejected'),
  ('[[Afrikaans]] or [[Dutch]]', 'rejected')
ON CONFLICT (alias) DO UPDATE
SET status = 'rejected',
    language_id = NULL,
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

-- A family of creoles rather than a form of French.
INSERT INTO wikidata_language_items (item_qid, item_label, status)
VALUES
  ('Q123161859', 'Caribbean French Creole languages', 'rejected')
ON CONFLICT (item_qid) DO UPDATE
SET status = 'rejected',
    language_id = NULL,
    date_updated = NOW()
WHERE wikidata_language_items.status = 'unreviewed';

COMMIT;
