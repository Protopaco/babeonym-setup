-- Drops the hierarchical reference functions from 005, 006 and 011.
--
-- get_name_filters (034) returns every filter option in one flat shape, and
-- both the desktop surface and the mobile filter bar now read only that. The
-- continent/region nesting these three returned has no remaining consumer:
-- their routes, db files and models are deleted from the backend.
--
-- The tables they read from are untouched. get_name_filters still selects from
-- decades, cultures, languages and regions.

DROP FUNCTION IF EXISTS get_reference_cultures();
DROP FUNCTION IF EXISTS get_reference_languages();
DROP FUNCTION IF EXISTS get_reference_decades();
