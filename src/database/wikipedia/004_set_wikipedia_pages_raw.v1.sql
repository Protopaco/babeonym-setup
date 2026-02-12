DROP FUNCTION IF EXISTS set_wikipedia_page_raw(
  int, int, text, jsonb, jsonb, text[], text, jsonb
);

CREATE OR REPLACE FUNCTION set_wikipedia_page_raw(
  p_requested_pageid int,
  p_resolved_pageid  int,
  p_resolved_title   text,
  p_infobox_json     jsonb,
  p_sections_json    jsonb,
  p_categories       text[],
  p_text     text,
  p_wtf_json         jsonb
)
RETURNS VOID AS $$
DECLARE
  v_is_redirect boolean;
BEGIN
  v_is_redirect := (p_resolved_pageid IS NOT NULL AND p_resolved_pageid <> p_requested_pageid);

  -- Increment hits + store redirect mapping
  UPDATE wikipedia_page_ids
  SET
    hits = hits + 1,
    resolved_pageid = CASE WHEN v_is_redirect THEN p_resolved_pageid ELSE NULL END,
    resolved_title  = CASE WHEN v_is_redirect THEN p_resolved_title  ELSE NULL END,
    is_redirect     = v_is_redirect,
    date_updated    = NOW()
  WHERE pageid = p_requested_pageid;

  -- Ensure resolved row exists
  INSERT INTO wikipedia_page_ids (source, pageid, title)
  SELECT
    wpi.source,
    p_resolved_pageid,
    COALESCE(p_resolved_title, wpi.title)
  FROM wikipedia_page_ids wpi
  WHERE wpi.pageid = p_requested_pageid
  ON CONFLICT (pageid) DO UPDATE
  SET
    title = EXCLUDED.title,
    date_updated = NOW();

  -- Upsert parsed data on resolved page
  INSERT INTO wikipedia_page_raw (
    pageid,
    infobox_json,
    sections_json,
    categories,
    text,
    wtf_json
  )
  VALUES (
    p_resolved_pageid,
    p_infobox_json,
    p_sections_json,
    COALESCE(p_categories, '{}'::text[]),
    p_text,
    p_wtf_json
  )
  ON CONFLICT (pageid) DO UPDATE
  SET
    infobox_json  = EXCLUDED.infobox_json,
    sections_json = EXCLUDED.sections_json,
    categories    = EXCLUDED.categories,
    text  = EXCLUDED.text,
    wtf_json      = EXCLUDED.wtf_json,
    date_updated  = NOW();
END;
$$ LANGUAGE plpgsql;
