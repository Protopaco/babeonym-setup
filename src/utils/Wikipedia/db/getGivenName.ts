import { query } from "../../postGresPool";

export default async (
  wikiName: string,
): Promise<{ id: number; givenName: string } | null> => {
  const res = await query(
    `SELECT id, given_name
FROM given_names
WHERE regexp_replace(lower(unaccent(given_name)), '[^a-z]', '', 'g')
    = regexp_replace(lower(unaccent($1::text)),   '[^a-z]', '', 'g')
LIMIT 1;
`,
    [wikiName],
  );
  if (res.rowCount === 0) {
    return null;
  }
  return {
    id: res.rows[0].id,
    givenName: res.rows[0].given_name,
  };
  //   }

  //   res.rows[0].map((row:any) => ({
  //     id: row.id,
  //     givenName: row.given_name,
  //   }))[0];
};
