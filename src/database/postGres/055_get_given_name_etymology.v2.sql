-- A given name's etymology, as one JSON value. See tickets [096] and [112].
--
-- Moved out of get_name_candidates (046) so the approved names list can carry
-- the same data without a second copy of the query. Both callers build it only
-- for the rows they return, so the cost is three indexed lookups per name.
--
--   {
--     meanings:  [{ id, text, language: { id, label, flag } | null }],
--     languages: [{ id, label, flag }],
--     cultures:  [{ id, label }]
--   } | null
--
-- Meanings come from meanings and given_name_meaning_bridge. A bridge row is unique
-- per source and extraction method, so the same meaning in the same language can
-- appear more than once; it is shown once. A meaning with no language gets a null
-- language rather than no key.
--
-- cultures has no flag column, so a culture carries no flag.
--
-- etymology is returned only for a name with at least one meaning or at least
-- three languages. Below that there is not enough to be worth opening, and every
-- caller treats a null as "this name has no etymology" — the indicator, the info
-- action and the modal all key off the same value, so they cannot disagree.
-- When it is present all three arrays are present, empty where there is nothing
-- to show.
--
-- STRICT, so a null id returns null without running the query. A custom name's
-- bridge row has no given_name_id, and a name typed by the user has no etymology.

CREATE OR REPLACE FUNCTION get_given_name_etymology(p_given_name_id INT)
RETURNS JSON
LANGUAGE sql
STABLE
STRICT
AS $$
  SELECT
    CASE
      WHEN COALESCE(json_array_length(e.meanings), 0) >= 1
        OR COALESCE(json_array_length(e.languages), 0) >= 3
      THEN json_build_object(
        'meanings',  COALESCE(e.meanings,  '[]'::json),
        'languages', COALESCE(e.languages, '[]'::json),
        'cultures',  COALESCE(e.cultures,  '[]'::json)
      )
      ELSE NULL
    END
  FROM (
    SELECT
      (
        SELECT json_agg(
          json_build_object(
            'id', m.id,
            'text', m.text,
            'language', CASE
              WHEN l.id IS NULL THEN NULL
              ELSE json_build_object('id', l.id, 'label', l.label, 'flag', l.flag)
            END
          )
          ORDER BY m.text, l.label
        )
        FROM (
          SELECT DISTINCT gnmb.meaning_id, gnmb.language_id
          FROM given_name_meaning_bridge gnmb
          WHERE gnmb.given_name_id = p_given_name_id
        ) mb
        JOIN meanings m
          ON m.id = mb.meaning_id
        LEFT JOIN languages l
          ON l.id = mb.language_id
      ) AS meanings,

      (
        SELECT json_agg(
          json_build_object('id', l.id, 'label', l.label, 'flag', l.flag)
          ORDER BY l.label
        )
        FROM given_name_language_bridge gnlb
        JOIN languages l
          ON l.id = gnlb.language_id
        WHERE gnlb.given_name_id = p_given_name_id
      ) AS languages,

      (
        SELECT json_agg(
          json_build_object('id', c.id, 'label', c.label)
          ORDER BY c.label
        )
        FROM given_name_culture_bridge gncb
        JOIN cultures c
          ON c.id = gncb.culture_id
        WHERE gncb.given_name_id = p_given_name_id
      ) AS cultures
  ) e;
$$;
