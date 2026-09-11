-- Languages found while reviewing the Wikidata language items, after
-- extraction ran over the full corpus. Continues 038, which covered the same
-- review on the Wiktionary side.
--
-- Seediq and Amis are indigenous languages of Taiwan, from the same family as
-- Atayal. Much of their weight comes from a block of Wikidata items created one
-- per name, whose English labels happen to match spellings in the SSA data —
-- Sita, Abu, Amen. The tag is kept anyway because it is additive: it takes
-- nothing from a name's other languages. Aragonese is a Romance language of
-- northeastern Spain, added on the same reasoning as Asturian.
--
-- Every flag is the 🌍 placeholder, matching 037 and 038. ON CONFLICT DO NOTHING
-- so a later pass that sets proper flags is not undone by re-running this file.

BEGIN;

INSERT INTO languages (label, flag) VALUES
('Seediq','🌍'),
('Amis','🌍'),
('Aragonese','🌍')
ON CONFLICT (label) DO NOTHING;

COMMIT;
