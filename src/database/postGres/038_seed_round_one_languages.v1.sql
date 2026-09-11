-- Languages found while reviewing the round-one Wiktionary language tokens,
-- covering the full 104,819-name corpus rather than the fifty-name sample that
-- produced 037.
--
-- Mostly living languages the reference list did not carry — Walloon, Atayal,
-- Asturian, Lun Bawang, Greenlandic, Ingrian, Tausug — plus three that are not
-- spoken as a first language today but are how a large number of names are
-- actually described: Sanskrit, Old Norse and Aramaic. Latin is already carried
-- on the same reasoning.
--
-- Old Norse is deliberately its own row rather than folded. It has five modern
-- descendants, so folding would mean picking one arbitrarily, and it is a label
-- someone browsing names would plausibly want in its own right.
--
-- Every flag is the 🌍 placeholder, matching 037: keeping them uniform means
-- "still needs a real flag" is a single query rather than a memory. ON CONFLICT
-- DO NOTHING so a later pass that sets proper flags is not undone by re-running.

BEGIN;

INSERT INTO languages (label, flag) VALUES
('Sanskrit','🌍'),
('Old Norse','🌍'),
('Walloon','🌍'),
('Atayal','🌍'),
('Asturian','🌍'),
('Esperanto','🌍'),
('Lun Bawang','🌍'),
('Greenlandic','🌍'),
('Ingrian','🌍'),
('Tausug','🌍'),
('Aramaic','🌍')
ON CONFLICT (label) DO NOTHING;

COMMIT;
