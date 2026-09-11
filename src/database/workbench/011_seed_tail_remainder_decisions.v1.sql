-- Decisions for the rest of the review tail: every token 009 and 010 did not
-- cover, so that nothing is left unreviewed. Reviewed 2026-09-11.
--
-- Three rules settle almost all of it.
--
--   A real language gets a row, however few names it has today (added by 041).
--   A historical or regional form folds into its language, as in 009 — for a
--     language already carried (Nynorsk to Norwegian, Valencian to Catalan) or
--     for one 041 adds (Upper Sorbian to Sorbian).
--   Families, proto-languages, origin categories and fragments of markup are
--     rejected, following 004 and 005. Rejecting only means "not a language":
--     surname, place name and fiction are true statements about where a name
--     came from, and their claims stay in name_claims.
--
-- The judgment calls, each made from the names the token actually tags:
--
--   Coptic keeps its own row rather than folding into Ancient Egyptian. Abanoub
--     is a Coptic Christian name, and Coptic is how those families describe it.
--   Hindustani keeps its own row. Its names split between Hindi (Anil, Kiran)
--     and Urdu (Hamza), and an alias can point at only one language.
--   Frankish, Old Turkic and Chagatai keep their own rows, following Old Norse:
--     each has several descendants. Folding Frankish into Dutch would have made
--     Robert and Lewis Dutch.
--   Fingallian keeps its own row, on the reasoning 040 gave its sister Yola.
--   Syriac folds into Aramaic, of which it is a form.
--   Taroko folds into Seediq, of which it is a dialect. Its names — Hanako,
--     Yuji — are the same spelling collisions that 039 noted for Seediq.
--   Frisian folds into West Frisian. Its names, Gerrit and Menno, are Frisian
--     names from the Netherlands.
--   Wallachian dialect folds into Romanian as a regional form.
--   Belurusian is a misspelling of Belarusian.
--
-- Depends on 041_seed_tail_remainder_languages.v1.sql having run, since the
-- mappings join languages on label. Wiktionary tokens are keyed on their text
-- and Wikidata items on their identifier, following 005, 007, 009 and 010. Safe
-- to re-run: a decision already recorded is not overwritten.

BEGIN;

-- Languages added by 041, including forms folded into a base 041 adds. 85 Wiktionary tokens.
INSERT INTO wiktionary_language_aliases (alias, language_id, status)
SELECT decided.alias, languages.id, 'mapped'
FROM (VALUES
  ('''Are''are',        '''Are''are'),
  ('Afar',              'Afar'),
  ('Egyptian',          'Ancient Egyptian'),
  ('Aromanian',         'Aromanian'),
  ('Assamese',          'Assamese'),
  ('Balinese',          'Balinese'),
  ('Betawi',            'Betawi'),
  ('Buginese',          'Buginese'),
  ('Carolinian',        'Carolinian'),
  ('Central Bikol',     'Central Bikol'),
  ('Chechen',           'Chechen'),
  ('Chinook',           'Chinook'),
  ('Dakota',            'Dakota'),
  ('Dalmatian',         'Dalmatian'),
  ('Emilian',           'Emilian'),
  ('Etruscan',          'Etruscan'),
  ('Ewe',               'Ewe'),
  ('Extremaduran',      'Extremaduran'),
  ('Fingallian',        'Fingallian'),
  ('Franco-Provençal',  'Franco-Provençal'),
  ('Frankish',          'Frankish'),
  ('Gothic',            'Gothic'),
  ('Guanche',           'Guanche'),
  ('Hanunoo',           'Hanunoo'),
  ('Hiligaynon',        'Hiligaynon'),
  ('Ilocano',           'Ilocano'),
  ('Istriot',           'Istriot'),
  ('Jamamadí',          'Jamamadí'),
  ('Kalenjin',          'Kalenjin'),
  ('Kanakanabu',        'Kanakanabu'),
  ('Kavalan',           'Kavalan'),
  ('Kaxuyana',          'Kaxuyana'),
  ('Kikuyu',            'Kikuyu'),
  ('Kui (Indonesia)',   'Kui (Indonesia)'),
  ('Ladino',            'Ladino'),
  ('Latgalian',         'Latgalian'),
  ('Leonese',           'Leonese'),
  ('Old Leonese',       'Leonese'),
  ('Limburgish',        'Limburgish'),
  ('Lombard',           'Lombard'),
  ('Louisiana Creole',  'Louisiana Creole'),
  ('Luo',               'Luo'),
  ('Luxembourgish',     'Luxembourgish'),
  ('Maguindanao',       'Maguindanao'),
  ('Malagasy',          'Malagasy'),
  ('Maltese',           'Maltese'),
  ('Mam',               'Mam'),
  ('Manado',            'Manado'),
  ('Mapudungun',        'Mapudungun'),
  ('Maranao',           'Maranao'),
  ('Mirandese',         'Mirandese'),
  ('Murui Huitoto',     'Murui Huitoto'),
  ('Classical Nahuatl', 'Nahuatl'),
  ('Navajo',            'Navajo'),
  ('Neapolitan',        'Neapolitan'),
  ('Nheengatu',         'Nheengatu'),
  ('Nobiin',            'Nobiin'),
  ('Old Median',        'Old Median'),
  ('Old Turkic',        'Old Turkic'),
  ('Oromo',             'Oromo'),
  ('Punic',             'Phoenician'),
  ('Puyuma',            'Puyuma'),
  ('Romani',            'Romani'),
  ('Rukai',             'Rukai'),
  ('Saaroa',            'Saaroa'),
  ('Northern Sami',     'Sami'),
  ('Sandawe',           'Sandawe'),
  ('Sherbro',           'Sherbro'),
  ('Soninke',           'Soninke'),
  ('Lower Sorbian',     'Sorbian'),
  ('Sranan Tongo',      'Sranan Tongo'),
  ('Thao',              'Thao'),
  ('Thracian',          'Thracian'),
  ('Tibetan',           'Tibetan'),
  ('Tocharian B',       'Tocharian B'),
  ('Tokelauan',         'Tokelauan'),
  ('Tongan',            'Tongan'),
  ('Old Tupi',          'Tupi'),
  ('Turkmen',           'Turkmen'),
  ('Ulwa (New Guinea)', 'Ulwa (New Guinea)'),
  ('Unami',             'Unami'),
  ('Vandalic',          'Vandalic'),
  ('Vilamovian',        'Vilamovian'),
  ('West Circassian',   'West Circassian'),
  ('Zazaki',            'Zazaki')
) AS decided (alias, language_label)
JOIN languages ON languages.label = decided.language_label
ON CONFLICT (alias) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

-- Languages added by 041, including forms folded into a base 041 adds. 71 Wikidata items.
INSERT INTO wikidata_language_items (item_qid, item_label, language_id, status)
SELECT decided.item_qid, decided.item_label, languages.id, 'mapped'
FROM (VALUES
  ('Q50868',    'Egyptian',            'Ancient Egyptian'),
  ('Q29316',    'Aromanian',           'Aromanian'),
  ('Q29401',    'Assamese',            'Assamese'),
  ('Q13389',    'Bashkir',             'Bashkir'),
  ('Q9303',     'Bosnian',             'Bosnian'),
  ('Q35963',    'Cape Verdean Creole', 'Cape Verdean Creole'),
  ('Q36831',    'Chagatai',            'Chagatai'),
  ('Q33281',    'Chavacano',           'Chavacano'),
  ('Q33350',    'Chechen',             'Chechen'),
  ('Q33348',    'Chuvash',             'Chuvash'),
  ('Q36155',    'Coptic',              'Coptic'),
  ('Q33111',    'Corsican',            'Corsican'),
  ('Q32238',    'Dagbanli',            'Dagbanli'),
  ('Q2914733',  'Dothraki',            'Dothraki'),
  ('Q35375',    'Edo',                 'Edo'),
  ('Q29952',    'Erzya',               'Erzya'),
  ('Q30005',    'Ewe',                 'Ewe'),
  ('Q35331',    'Farefare',            'Farefare'),
  ('Q3094789',  'Gallaecian',          'Gallaecian'),
  ('Q37300',    'Gallo',               'Gallo'),
  ('Q35722',    'Gothic',              'Gothic'),
  ('Q2149691',  'Visigothic',          'Gothic'),
  ('Q35762',    'Guanche',             'Guanche'),
  ('Q64483808', 'High Valyrian',       'High Valyrian'),
  ('Q11051',    'Hindustani',          'Hindustani'),
  ('Q33792',    'Ibibio',              'Ibibio'),
  ('Q35478',    'Idoma',               'Idoma'),
  ('Q35939',    'Jamaican Patois',     'Jamaican Patois'),
  ('Q33557',    'Karelian',            'Karelian'),
  ('Q33537',    'Lakota',              'Lakota'),
  ('Q102172',   'Limburgish',          'Limburgish'),
  ('Q36217',    'Lingala',             'Lingala'),
  ('Q33754',    'Lombard',             'Lombard'),
  ('Q9051',     'Luxembourgish',       'Luxembourgish'),
  ('Q36109',    'Maithili',            'Maithili'),
  ('Q7930',     'Malagasy',            'Malagasy'),
  ('Q9166',     'Maltese',             'Maltese'),
  ('Q33730',    'Mapudungun',          'Mapudungun'),
  ('Q13300',    'Nahuatl',             'Nahuatl'),
  ('Q13307',    'Nauruan',             'Nauruan'),
  ('Q58680',    'Pashto',              'Pashto'),
  ('Q36734',    'Phoenician',          'Phoenician'),
  ('Q535958',   'Punic',               'Phoenician'),
  ('Q34024',    'Picard',              'Picard'),
  ('Q36746',    'Rapa Nui',            'Rapa Nui'),
  ('Q716695',   'Saisiyat',            'Saisiyat'),
  ('Q33947',    'Northern Sami',       'Sami'),
  ('Q56463',    'Sámi',                'Sami'),
  ('Q33902',    'Saraiki',             'Saraiki'),
  ('Q33976',    'Sardinian',           'Sardinian'),
  ('Q34015',    'Seychellois Creole',  'Seychellois Creole'),
  ('Q36705',    'Shelta',              'Shelta'),
  ('Q30319',    'Silesian',            'Silesian'),
  ('Q56437',    'Sindarin',            'Sindarin'),
  ('Q33997',    'Sindhi',              'Sindhi'),
  ('Q13286',    'Lower Sorbian',       'Sorbian'),
  ('Q25442',    'Sorbian',             'Sorbian'),
  ('Q13248',    'Upper Sorbian',       'Sorbian'),
  ('Q34014',    'Swazi',               'Swazi'),
  ('Q34128',    'Tahitian',            'Tahitian'),
  ('Q9260',     'Tajik',               'Tajik'),
  ('Q25285',    'Tatar',               'Tatar'),
  ('Q34271',    'Tibetan',             'Tibetan'),
  ('Q34094',    'Tongan',              'Tongan'),
  ('Q7842493',  'Trinidadian Creole',  'Trinidadian Creole'),
  ('Q56944',    'Tupi',                'Tupi'),
  ('Q34055',    'Tuvaluan',            'Tuvaluan'),
  ('Q36663',    'Urhobo',              'Urhobo'),
  ('Q32724',    'Venetian',            'Venetian'),
  ('Q32747',    'Veps',                'Veps'),
  ('Q34299',    'Yakut',               'Yakut')
) AS decided (item_qid, item_label, language_label)
JOIN languages ON languages.label = decided.language_label
ON CONFLICT (item_qid) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wikidata_language_items.status = 'unreviewed';

-- Forms folded into a language already carried. 12 Wiktionary tokens.
INSERT INTO wiktionary_language_aliases (alias, language_id, status)
SELECT decided.alias, languages.id, 'mapped'
FROM (VALUES
  ('Classical Syriac', 'Aramaic'),
  ('Belurusian',       'Belarusian'),
  ('Hokkien',          'Chinese'),
  ('Mandarin',         'Chinese'),
  ('Bavarian',         'German'),
  ('Erzgebirgisch',    'German'),
  ('Hunsrik',          'German'),
  ('Kawi',             'Javanese'),
  ('Middle Mongol',    'Mongolian'),
  ('Provençal',        'Occitan'),
  ('Dari',             'Persian'),
  ('Taroko',           'Seediq')
) AS decided (alias, language_label)
JOIN languages ON languages.label = decided.language_label
ON CONFLICT (alias) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

-- Forms folded into a language already carried. 8 Wikidata items.
INSERT INTO wikidata_language_items (item_qid, item_label, language_id, status)
SELECT decided.item_qid, decided.item_label, languages.id, 'mapped'
FROM (VALUES
  ('Q2669806',  'Kaaps',              'Afrikaans'),
  ('Q33538',    'Syriac',             'Aramaic'),
  ('Q32641',    'Valencian',          'Catalan'),
  ('Q25164',    'Nynorsk',            'Norwegian'),
  ('Q35735',    'Gascon',             'Occitan'),
  ('Q36392',    'Moldovan',           'Romanian'),
  ('Q25975639', 'Wallachian dialect', 'Romanian'),
  ('Q25325',    'Frisian',            'West Frisian')
) AS decided (item_qid, item_label, language_label)
JOIN languages ON languages.label = decided.language_label
ON CONFLICT (item_qid) DO UPDATE
SET language_id = EXCLUDED.language_id,
    status = 'mapped',
    date_updated = NOW()
WHERE wikidata_language_items.status = 'unreviewed';

-- Not languages. 38 Wiktionary tokens.
INSERT INTO wiktionary_language_aliases (alias, status)
VALUES
  ('[[Éamann]]', 'rejected'),
  ('a combination of [[James]] and [[Len]]', 'rejected'),
  ('a {{lg|clipping}} of ''''[[Percival]]''''', 'rejected'),
  ('Ancient [[Persia]] often used in [[India]]', 'rejected'),
  ('Bantu languages', 'rejected'),
  ('Celtic', 'rejected'),
  ('diminutives', 'rejected'),
  ('Dravidian languages', 'rejected'),
  ('fiction', 'rejected'),
  ('Germanic', 'rejected'),
  ('Goidelic', 'rejected'),
  ('Goidelic languages', 'rejected'),
  ('Indo-Aryan languages', 'rejected'),
  ('month names', 'rejected'),
  ('North Germanic languages', 'rejected'),
  ('occupations', 'rejected'),
  ('Odia and Santali', 'rejected'),
  ('place name', 'rejected'),
  ('Polynesian', 'rejected'),
  ('Polynesian languages', 'rejected'),
  ('popular culture', 'rejected'),
  ('Proto-Brythonic', 'rejected'),
  ('Proto-Celtic', 'rejected'),
  ('Proto-Dravidian', 'rejected'),
  ('Proto-Turkic', 'rejected'),
  ('Romance languages', 'rejected'),
  ('Scandinavian languages', 'rejected'),
  ('Scottish', 'rejected'),
  ('Slavic', 'rejected'),
  ('South Asia', 'rejected'),
  ('South Asian Languages', 'rejected'),
  ('South Asian languages', 'rejected'),
  ('surname', 'rejected'),
  ('surname or variant of {{l|en|Emery}}', 'rejected'),
  ('the surname', 'rejected'),
  ('time', 'rejected'),
  ('toponyms', 'rejected'),
  ('West Germanic languages', 'rejected')
ON CONFLICT (alias) DO UPDATE
SET status = 'rejected',
    language_id = NULL,
    date_updated = NOW()
WHERE wiktionary_language_aliases.status = 'unreviewed';

-- Not languages. 16 Wikidata items.
INSERT INTO wikidata_language_items (item_qid, item_label, status)
VALUES
  ('Q25448', 'Berber', 'rejected'),
  ('Q156877', 'Brythonic', 'rejected'),
  ('Q25293', 'Celtic languages', 'rejected'),
  ('Q5278362', 'Dinka alphabet', 'rejected'),
  ('Q56433', 'Goidelic', 'rejected'),
  ('Q51739', 'Indigenous languages of the Americas', 'rejected'),
  ('Q33577', 'Indo-Aryan', 'rejected'),
  ('Q19860', 'Indo-European', 'rejected'),
  ('Q1339026', 'languages of Guinea', 'rejected'),
  ('Q16723056', 'languages of Saint Kitts and Nevis', 'rejected'),
  ('Q390979', 'Polynesian', 'rejected'),
  ('Q10958896', 'Polynesian', 'rejected'),
  ('Q34049', 'Semitic', 'rejected'),
  ('Q23526', 'Slavic', 'rejected'),
  ('Q34090', 'Turkic', 'rejected'),
  ('Q22282914', 'undetermined language', 'rejected')
ON CONFLICT (item_qid) DO UPDATE
SET status = 'rejected',
    language_id = NULL,
    date_updated = NOW()
WHERE wikidata_language_items.status = 'unreviewed';

COMMIT;
