-- Rebuilds given_name_popularity_overall to classify male-only names.
--
-- female_share was computed as female_total / mf_total, where female_total is a
-- SUM(...) FILTER (WHERE gender = 'female'). A filtered SUM over no rows returns
-- null rather than zero, so a name with no recorded female occurrences divided
-- null by its total and got a null share. That carried into a null
-- gender_difference, which get_name_candidates maps to NULL::gender in its
-- classification CASE, and NULL = ANY(...) is never true. The result is that a
-- male-only name matched no gender filter at all — the most unambiguously male
-- names were the ones a male filter could not find.
--
-- Female-only names were never affected: their female total and their
-- male-female total are the same number, so the share came out 1.0.
--
-- Measured against prod before the fix: 33,173 of 104,819 names were
-- unclassified, every one of them male-only, none female-only or mixed. 1,841 of
-- the 10,004 rows inside the rank <= 5,000 tier windows were affected, so this
-- was not confined to the unreachable tail.
--
-- The fix is to read an absent female total as zero. A male-only name then gets
-- a female_share of 0.0 and a gender_difference of 1.0, and classifies as male.
--
-- mf_total is left guarded by NULLIF. A null there means the name has no male or
-- female occurrences at all, which is a genuine unknown rather than a zero, and
-- such a name should stay unclassified.
--
-- Everything else is 045 verbatim: same columns, same rank and percentile
-- formulas, same per-gender partitioning. Only the two expressions that read
-- female_total change, so ranks and occurrence totals are untouched.
--
-- seed/namePopularityByDecade.v1.sql carries the identical formula and is fixed
-- in the same change. The two tables have to agree, or a name answers a gender
-- filter differently depending on whether a decade was picked.
--
-- Derived data with no other writer, so this is a truncate and a rebuild. The
-- table and its indexes come from 045 and are not recreated here.

BEGIN;

TRUNCATE TABLE "given_name_popularity_overall" RESTART IDENTITY;

WITH agg AS (
  SELECT
    occ.given_name_id,
    occ.gender,
    SUM(occ.occurrences) AS total_occ
  FROM given_name_occurrences occ
  GROUP BY occ.given_name_id, occ.gender
),

totals AS (
  SELECT
    given_name_id,
    SUM(total_occ) FILTER (WHERE gender IN ('male', 'female')) AS mf_total,
    SUM(total_occ) FILTER (WHERE gender = 'female') AS female_total
  FROM agg
  GROUP BY given_name_id
),

ranked AS (
  SELECT
    a.*,
    RANK() OVER (PARTITION BY a.gender ORDER BY a.total_occ DESC) AS rnk,
    COUNT(*) OVER (PARTITION BY a.gender) AS n
  FROM agg a
)

INSERT INTO given_name_popularity_overall (
  given_name_id,
  gender,
  rank,
  percentile,
  total_occurrences,
  female_share,
  gender_difference,
  date_created
)
SELECT
  r.given_name_id,
  r.gender,
  r.rnk AS rank,
  CASE
    WHEN r.n = 1 THEN 1::numeric
    ELSE 1::numeric - ((r.rnk - 1)::numeric / (r.n - 1)::numeric)
  END AS percentile,

  r.total_occ AS total_occurrences,

  (COALESCE(t.female_total, 0)::numeric / NULLIF(t.mf_total, 0)) AS female_share,

  ABS((COALESCE(t.female_total, 0)::numeric / NULLIF(t.mf_total, 0)) - 0.5) * 2 AS gender_difference,

  NOW() AS date_created
FROM ranked r
JOIN totals t
  ON t.given_name_id = r.given_name_id;

COMMIT;
