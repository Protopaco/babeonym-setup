import { query } from "./wikipool";

export default async (pageid: number): Promise<string | null> => {
  const res = await query(`SELECT * FROM get_page_infobox($1);`, [pageid]);
  if (res.rows.length === 0) {
    return null;
  }
  return res.rows[0];
};
