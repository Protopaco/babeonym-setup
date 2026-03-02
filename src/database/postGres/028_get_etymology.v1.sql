DROP FUNCTION IF EXISTS get_etymology(INT);

CREATE OR REPLACE FUNCTION get_etymology(p_given_custom_name_bridge_id INT)
RETURNS JSONB
LANGUAGE sql
STABLE
AS $$
  SELECT jsonb_build_object(
    'givenCustomNameBridgeId', gcnb.id,
    'givenName', gn.given_name,

    'languages', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', l.id,
          'label', l.label,
          'flag', l.flag
        )
        ORDER BY l.label
      )
      FROM given_name_language_bridge gnlb
      JOIN languages l ON l.id = gnlb.language_id
      WHERE gnlb.given_name_id = gn.id
    ), '[]'::jsonb),

    'cultures', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', c.id,
          'label', c.label
        )
        ORDER BY c.label
      )
      FROM given_name_culture_bridge gncb
      JOIN cultures c ON c.id = gncb.culture_id
      WHERE gncb.given_name_id = gn.id
    ), '[]'::jsonb),

    'meaning', COALESCE((
      SELECT jsonb_build_object(
        'short', gnm.meaning_short,
        'long',  gnm.meaning_long,
        'dateCreated', gnm.date_created,
        'dateUpdated', gnm.date_updated
      )
      FROM given_name_meaning gnm
      WHERE gnm.given_name_id = gn.id
    ), jsonb_build_object(
      'short', NULL,
      'long', NULL,
      'dateCreated', NULL,
      'dateUpdated', NULL
    ))
  )
  FROM given_custom_name_bridge gcnb
  JOIN given_names gn
    ON gn.id = gcnb.given_name_id
  WHERE gcnb.id = p_given_custom_name_bridge_id;
$$;
