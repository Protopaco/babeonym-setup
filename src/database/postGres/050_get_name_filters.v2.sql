-- get_name_filters (034) with a floor on cultures and languages: an option is
-- only offered when at least 10 names carry it. A filter that matches almost
-- nothing is worse than no filter. Genders and decades are unchanged, and so is
-- everything else in 034, which carries the reasoning for the shape.
--
-- Names are counted from the bridge tables get_name_candidates filters on, so
-- an offered option has at least that many names behind it. The count is per
-- option, not per combination: culture plus decade plus gender can still come
-- back empty, and that is accepted rather than predicted here.
--
-- A subquery rather than a join, so the region joins cannot inflate the count.
--
-- The return type is unchanged, so CREATE OR REPLACE is enough.

CREATE OR REPLACE FUNCTION get_name_filters()
RETURNS TABLE (
  out_filter_type TEXT,
  out_id INT,
  out_label TEXT,
  out_search_text TEXT
)
LANGUAGE sql
STABLE
AS $$
  WITH options AS (
    SELECT
      1 AS type_rank,
      'gender'::TEXT AS filter_type,
      g.id,
      g.label,
      g.search_text,
      lpad(g.id::TEXT, 5, '0') AS sort_key
    FROM genders g

    UNION ALL

    SELECT
      2,
      'decade'::TEXT,
      d.id,
      d.label,
      lower(concat_ws(' ', d.label, d.decade::TEXT, 'decade')),
      -- Newest decade first, as a text key the outer sort can share.
      lpad((9999 - d.decade)::TEXT, 5, '0')
    FROM decades d

    UNION ALL

    SELECT
      3,
      'culture'::TEXT,
      cu.id,
      cu.label,
      -- concat_ws drops the NULLs a culture with no region would produce.
      lower(concat_ws(
        ' ',
        cu.label,
        string_agg(DISTINCT r.label, ' '),
        string_agg(DISTINCT c.label, ' ')
      )),
      lower(cu.label)
    FROM cultures cu
    LEFT JOIN culture_region_bridge crb
      ON crb.culture_id = cu.id
    LEFT JOIN regions r
      ON r.id = crb.region_id
    LEFT JOIN regions c
      ON c.id = r.parent_id
    WHERE (
      SELECT COUNT(DISTINCT gncb.given_name_id)
      FROM given_name_culture_bridge gncb
      WHERE gncb.culture_id = cu.id
    ) >= 10
    GROUP BY cu.id, cu.label

    UNION ALL

    SELECT
      4,
      'language'::TEXT,
      l.id,
      l.label,
      lower(concat_ws(
        ' ',
        l.label,
        string_agg(DISTINCT r.label, ' '),
        string_agg(DISTINCT c.label, ' ')
      )),
      lower(l.label)
    FROM languages l
    LEFT JOIN language_region_bridge lrb
      ON lrb.language_id = l.id
    LEFT JOIN regions r
      ON r.id = lrb.region_id
    LEFT JOIN regions c
      ON c.id = r.parent_id
    WHERE (
      SELECT COUNT(DISTINCT gnlb.given_name_id)
      FROM given_name_language_bridge gnlb
      WHERE gnlb.language_id = l.id
    ) >= 10
    GROUP BY l.id, l.label
  )

  SELECT
    o.filter_type  AS out_filter_type,
    o.id           AS out_id,
    o.label        AS out_label,
    o.search_text  AS out_search_text
  FROM options o
  ORDER BY o.type_rank, o.sort_key;
$$;
