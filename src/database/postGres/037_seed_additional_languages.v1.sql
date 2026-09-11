-- Languages found in Wiktionary given-name entries that the original seed did
-- not carry.
--
-- Every flag is the 🌍 placeholder already used for Quechua and Hawaiian, even
-- where an obvious one exists (Cebuano, Tagalog and Kapampangan are all 🇵🇭).
-- Keeping them uniform means "still needs a real flag" is a single query rather
-- than a memory. ON CONFLICT DO NOTHING so a later pass that sets proper flags
-- is not undone by re-running this file.

BEGIN;

INSERT INTO languages (label, flag) VALUES
('Cebuano','🌍'),
('Tagalog','🌍'),
('Faroese','🌍'),
('Cornish','🌍'),
('Scots','🌍'),
('Norman','🌍'),
('Serbo-Croatian','🌍'),
('Occitan','🌍'),
('Manx','🌍'),
('Kashubian','🌍'),
('Kapampangan','🌍'),
('Cimbrian','🌍')
ON CONFLICT (label) DO NOTHING;

COMMIT;
