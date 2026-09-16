-- Rebuilds given_name_popularity_overall so rank reflects recent popularity
-- rather than all-time totals.
--
-- 045 ranked by the sum of every year of occurrences, which treats the 1880s and
-- the 2010s as equally relevant. That is technically true and practically wrong:
-- the top names of the 1880s are now largely obscure, so an unfiltered batch led
-- with names no one recognises. With no filters set the user has told us nothing,
-- and the reasonable default is mostly names they know, with enough older ones
-- left reachable to keep the mix interesting.
--
-- Score is built from percentile, not occurrences. Birth volumes and naming
-- diversity changed enormously over the century — the top name of the 1950s took
-- roughly 4% of all births, today's takes closer to 1% — so raw counts favour
-- mid-century names regardless of how the decades are weighted. Percentile is
-- rank expressed per decade and per gender, so #1 in the 2020s and #1 in the
-- 1950s score the same. It also makes a partially recorded current decade
-- harmless: fewer years means fewer births counted, but not a worse rank.
--
-- The scores are summed rather than averaged, so a name that placed well across
-- all four recent decades outranks one that spiked in a single decade. An older
-- name accumulates across many decades at a tenth of the value each, so it still
-- earns a rank and can surface below the first tiers rather than being excluded.
-- That tail is the "interesting" half of the mix and is meant to be reachable.
--
-- Both tuning values live in the tuning CTE below. Changing either is a one-line
-- edit and a re-run: this file truncates and rebuilds, so it is safe to run
-- repeatedly. Judge a setting by reading the top 100 per gender and asking
-- whether it looks like names in use now, compared against the previous setting
-- rather than an absolute standard. Expect more than one pass.
--
-- The four most recent decades are taken from the data. Decades are derived from
-- the occurrence years by the by-decade seed, so hardcoding them would go stale
-- the first time a new year of SSA data is loaded.
--
-- total_occurrences stays the true all-time sum, and female_share and
-- gender_difference keep 052's COALESCE — a filtered SUM over no rows returns
-- null, and writing 045's version here would silently restore the null share on
-- male-only names and drop 33,173 names out of every gender filter again. Only
-- what rank is derived from changes.
--
-- Reads given_name_popularity_by_decade, so that table must be current. Re-run
-- seed/namePopularityByDecade.v1.sql first if the underlying occurrence data has
-- changed.
--
-- Derived data with no other writer, so this is a truncate and a rebuild. The
-- table and its indexes come from 045 and are not recreated here.

BEGIN;

TRUNCATE TABLE "given_name_popularity_overall" RESTART IDENTITY;

WITH tuning AS (
  SELECT
    4 AS recent_decade_count,
    0.1::numeric AS older_decade_weight
),

recent_decades AS (
  SELECT d.id
  FROM decades d
  ORDER BY d.decade DESC
  LIMIT (SELECT recent_decade_count FROM tuning)
),

-- One weighted score per name per gender. A decade the name never appeared in
-- contributes nothing, so a name confined to one decade is scored on that decade
-- alone.
scored AS (
  SELECT
    p.given_name_id,
    p.gender,
    SUM(
      p.percentile
      * CASE
          WHEN p.decade_id IN (SELECT id FROM recent_decades) THEN 1::numeric
          ELSE (SELECT older_decade_weight FROM tuning)
        END
    ) AS score
  FROM given_name_popularity_by_decade p
  GROUP BY p.given_name_id, p.gender
),

-- The all-time occurrence totals, unweighted. These are reported, not ranked on.
agg AS (
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
    s.*,
    RANK() OVER (PARTITION BY s.gender ORDER BY s.score DESC) AS rnk,
    COUNT(*) OVER (PARTITION BY s.gender) AS n
  FROM scored s
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

  a.total_occ AS total_occurrences,

  (COALESCE(t.female_total, 0)::numeric / NULLIF(t.mf_total, 0)) AS female_share,

  ABS((COALESCE(t.female_total, 0)::numeric / NULLIF(t.mf_total, 0)) - 0.5) * 2 AS gender_difference,

  NOW() AS date_created
FROM ranked r
JOIN agg a
  ON a.given_name_id = r.given_name_id
 AND a.gender = r.gender
JOIN totals t
  ON t.given_name_id = r.given_name_id;

COMMIT;
