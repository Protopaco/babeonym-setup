-- Languages found while working through the review tail — tokens seen for ten
-- or more names that were real languages with no reference row. Continues 039.
--
-- West Frisian is the living language of Friesland and English's closest living
-- relative. Sicilian is a Romance language that developed separately from
-- Italian, added on the same footing as Asturian and Walloon rather than folded
-- as a regional form. Sakizaya and Pazeh are indigenous languages of Taiwan,
-- from the same family as Atayal, Seediq and Amis.
--
-- Two are extinct and kept anyway, following Old Norse. Yola, of County
-- Wexford, grew out of medieval English but developed on its own for centuries,
-- so it is not simply an old stage of English. Illyrian survives almost only as
-- personal and place names recorded by Greek and Roman writers — which is what
-- makes it relevant here — and is how Albanian naming tradition describes names
-- like Agron and Gent. It is not folded into Albanian, since descent from it is
-- still debated.
--
-- Every flag is the 🌍 placeholder, matching 037 to 039. ON CONFLICT DO NOTHING
-- so a later pass that sets proper flags is not undone by re-running this file.

BEGIN;

INSERT INTO languages (label, flag) VALUES
('West Frisian','🌍'),
('Yola','🌍'),
('Sakizaya','🌍'),
('Pazeh','🌍'),
('Illyrian','🌍'),
('Sicilian','🌍')
ON CONFLICT (label) DO NOTHING;

COMMIT;
