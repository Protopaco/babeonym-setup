import { query } from "./wikipool";

export default async (returns: number | null) => {
  console.log("\n→ Getting raw Wikipedia pages to parse...");
  const { rows } = await query(
    `SELECT * FROM get_wikipedia_pages_raw_to_parse($1)`,
    [returns],
  );
  return rows;
};
