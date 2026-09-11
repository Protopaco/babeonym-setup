INSERT INTO data_sources (
  source_type,
  label,
  base_url,
  license_note
) VALUES
  (
    'wiktionary',
    'Wiktionary',
    'https://en.wiktionary.org',
    'Open source reference data; preserve source document provenance before publishing derived facts.'
  ),
  (
    'wikidata',
    'Wikidata',
    'https://www.wikidata.org',
    'Open structured reference data; preserve source entity provenance before publishing derived facts.'
  ),
  (
    'manual',
    'Manual Review',
    NULL,
    'Human-reviewed or manually entered claims.'
  ),
  (
    'other',
    'Other',
    NULL,
    'Fallback source bucket for future evaluated sources.'
  )
ON CONFLICT (label) DO UPDATE
SET source_type = EXCLUDED.source_type,
    base_url = EXCLUDED.base_url,
    license_note = EXCLUDED.license_note;
