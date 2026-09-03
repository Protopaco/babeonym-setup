-- Adds a genders reference table so gender can be filtered by id like every
-- other filter, and so its search terms live beside the other reference data
-- rather than being hardcoded in the client.
--
-- The gender enum and the stored gender columns on given_name_occurrences and
-- given_name_popularity_by_decade are untouched. Candidate filtering never read
-- those columns anyway: it derives gender at query time from gender_difference
-- and female_share. This table only maps an id to the enum value that CASE
-- produces, so no name data changes.
--
-- Ids are assigned explicitly rather than left to the sequence. The client
-- already treats filter ids as stable, and reseeding should not renumber them.

CREATE TABLE IF NOT EXISTS "genders" (
  "id" SERIAL PRIMARY KEY,
  "value" gender UNIQUE NOT NULL,
  "label" TEXT NOT NULL,
  "search_text" TEXT NOT NULL
);

INSERT INTO genders (id, value, label, search_text)
VALUES
  (1, 'neutral', 'Neutral', 'neutral gender neutral unisex nonbinary'),
  (2, 'female',  'Female',  'female feminine girl women woman'),
  (3, 'male',    'Male',    'male masculine boy men man')
ON CONFLICT (id) DO UPDATE
  SET value       = EXCLUDED.value,
      label       = EXCLUDED.label,
      search_text = EXCLUDED.search_text;

-- Explicit ids leave the sequence behind the highest row, so the next insert
-- without an id would collide.
SELECT setval(
  pg_get_serial_sequence('genders', 'id'),
  (SELECT MAX(id) FROM genders)
);
