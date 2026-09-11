-- The last languages found behind meanings, continuing 042.
--
-- Dyula and Mandinka keep their own rows beside Bambara, which 042 added. All
-- three belong to the Manding group and are close relatives, but each is a
-- distinct language with its own speakers: Dyula in Burkina Faso and Côte
-- d'Ivoire, Mandinka in the Gambia, Senegal and Guinea-Bissau.
--
-- Mari stands for both of its written standards, following Sorbian and Sami in
-- 041. Western (Hill) Mari folds into it.
--
-- Every flag is the 🌍 placeholder, matching 037 to 042. ON CONFLICT DO NOTHING
-- so a later pass that sets proper flags is not undone by re-running this file.

BEGIN;

INSERT INTO languages (label, flag) VALUES
('Dyula','🌍'),
('Mandinka','🌍'),
('Mari','🌍')
ON CONFLICT (label) DO NOTHING;

COMMIT;
