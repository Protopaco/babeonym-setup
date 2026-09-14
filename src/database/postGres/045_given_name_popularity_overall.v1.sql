-- The all-time rollup of name popularity: one row per name per gender, with no
-- decade dimension.
--
-- get_name_candidates serves names in tiers, and a tier is a range of ranks.
-- With a decade filter that rank comes from given_name_popularity_by_decade.
-- Without one there was no rank to reach for, so the query summed all 410,809
-- decade rows on every request — 272ms to compute an answer that never changes,
-- since the SSA data only grows by a year at a time.
--
-- Columns and formulas mirror the by-decade seed exactly, minus decade_id, so a
-- caller can read either table with the same query and get the same shape back.
-- That is the point of the table: it makes the filtered and unfiltered paths one
-- piece of code rather than two.
--
-- Rank is per gender. A single blended ranking puts nine boys' names in the top
-- ten — James, John, Robert, Michael, William, then Mary — so the first screens a
-- new user sees would skew male. Ranking within gender makes James rank 1 male and
-- Mary rank 1 female, and both land in the top tier.
--
-- female_share is null for a name with no occurrences of the other gender, which
-- carries through to gender_difference and leaves such a name unclassified. That
-- is what the by-decade seed does and this mirrors it deliberately: the two tables
-- have to agree, or the same name answers a gender filter differently depending on
-- whether a decade was picked. It is worth fixing, but in both places at once.
--
-- Derived data with no other writer, so a refill is a truncate and a rebuild.
-- Re-run this file whenever new name data is loaded.

BEGIN;

CREATE TABLE IF NOT EXISTS "given_name_popularity_overall" (
  "id" SERIAL PRIMARY KEY,
  "given_name_id" INT NOT NULL REFERENCES "given_names" ("id"),
  "gender" gender NOT NULL,
  "rank" INT NOT NULL,
  "percentile" NUMERIC NOT NULL CHECK ("percentile" >= 0 AND "percentile" <= 1),
  "total_occurrences" BIGINT,
  "female_share" NUMERIC,
  "gender_difference" NUMERIC,
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE ("given_name_id", "gender")
);

-- The candidates query reads this table by gender and walks a rank window, so it
-- wants the two together and in rank order.
CREATE INDEX IF NOT EXISTS "given_name_popularity_overall_gender_rank_idx"
  ON "given_name_popularity_overall" ("gender", "rank");

-- The same access pattern against the by-decade table, which has carried nothing
-- but its primary key until now and has been sequentially scanned on every call.
CREATE INDEX IF NOT EXISTS "given_name_popularity_by_decade_decade_gender_rank_idx"
  ON "given_name_popularity_by_decade" ("decade_id", "gender", "rank");

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

  (t.female_total::numeric / NULLIF(t.mf_total, 0)) AS female_share,

  ABS((t.female_total::numeric / NULLIF(t.mf_total, 0)) - 0.5) * 2 AS gender_difference,

  NOW() AS date_created
FROM ranked r
JOIN totals t
  ON t.given_name_id = r.given_name_id;

COMMIT;
