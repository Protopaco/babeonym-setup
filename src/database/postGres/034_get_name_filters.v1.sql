-- Returns every filter option the name workspace offers as one flat list, so
-- the client makes a single call instead of three plus a hardcoded gender list.
--
-- Every option has the same shape: an id, a label, and the text a type-ahead
-- searches against. The continent/region hierarchy the culture and language
-- reference functions return is deliberately dropped here. The hierarchy's
-- only remaining job was helping people find an option, and folding the region
-- and continent names into search_text does that without the nesting.
--
-- Rows come back grouped by filter type and already ordered within each group:
-- genders in list order, decades newest first, cultures and languages
-- alphabetical. The caller only has to split them.
--
-- The existing get_reference_cultures, get_reference_languages and
-- get_reference_decades functions stay: the mobile accordions still consume the
-- hierarchical shape.

DROP FUNCTION IF EXISTS get_name_filters();

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
