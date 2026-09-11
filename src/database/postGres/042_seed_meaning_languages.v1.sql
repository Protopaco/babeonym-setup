-- The languages found behind meanings rather than behind origins. A meaning
-- such as "May Bel protect the king" for Balthazar is glossed on a derivation
-- template that names its own source language — Akkadian — and those languages
-- were never written in a from= field, so the origin review never saw them.
--
-- Each carries a meaning or a handful today, and is added anyway, on the same
-- reasoning as 041: a row is cheap, and a name's details can show a language
-- whatever its size.
--
-- The judgment calls:
--
--   Old Church Slavonic and Old East Slavic keep their own rows, following Old
--     Norse: each has several descendants rather than one base to fold into.
--   Cumbric and Sudovian keep their own rows. They are sister languages of Welsh
--     and Lithuanian, not earlier forms of them.
--   Venetic is not Venetian. It is an unrelated ancient language of the same
--     region; Venetian descends from Latin.
--   Zapotec is one row, though it is a cluster of related languages, because
--     Wiktionary treats it as one — as Chinese is treated here.
--
-- Every flag is the 🌍 placeholder, matching 037 to 041. ON CONFLICT DO NOTHING
-- so a later pass that sets proper flags is not undone by re-running this file.

BEGIN;

INSERT INTO languages (label, flag) VALUES
('Akkadian','🌍'),
('Bambara','🌍'),
('Caddo','🌍'),
('Central Atlas Tamazight','🌍'),
('Cumbric','🌍'),
('East Circassian','🌍'),
('Evenki','🌍'),
('Gaulish','🌍'),
('Hittite','🌍'),
('Kanuri','🌍'),
('O''odham','🌍'),
('Old Church Slavonic','🌍'),
('Old East Slavic','🌍'),
('Pictish','🌍'),
('Shawnee','🌍'),
('Sudovian','🌍'),
('Sumerian','🌍'),
('Tarifit','🌍'),
('Venetic','🌍'),
('Yami','🌍'),
('Yana','🌍'),
('Yucatec Maya','🌍'),
('Zapotec','🌍')
ON CONFLICT (label) DO NOTHING;

COMMIT;
