INSERT INTO regions (id, label, parent_id) VALUES
  (1,  'Africa',   NULL),
  (2,  'Europe',   NULL),
  (3,  'Asia',     NULL),
  (4,  'Oceania',  NULL),
  (5,  'Americas', NULL),

  (10, 'North Africa',              1),
  (11, 'West Africa',               1),
  (12, 'East Africa',               1),
  (13, 'Southern & Central Africa', 1),

  (20, 'British Isles',   2),
  (21, 'Northern Europe', 2),
  (22, 'Western Europe',  2),
  (23, 'Southern Europe', 2),
  (24, 'Central Europe',  2),
  (25, 'Eastern Europe',  2),
  (26, 'Balkans',         2),
  (27, 'Pan-European',    2),

  (30, 'West Asia & Caucasus', 3),
  (31, 'Central Asia',         3),
  (32, 'South Asia',           3),
  (33, 'East Asia',            3),
  (34, 'Southeast Asia',       3),

  (40, 'Australia & New Zealand', 4),
  (41, 'Polynesia',               4),
  (42, 'Melanesia',               4),

  (50, 'North America', 5),
  (51, 'Caribbean',     5),
  (52, 'South America', 5)

ON CONFLICT (id) DO UPDATE
SET label = EXCLUDED.label,
    parent_id = EXCLUDED.parent_id;
    