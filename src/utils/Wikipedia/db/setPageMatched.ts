import { query } from "./wikipool";

export default async (pageid: number): Promise<void> => {
  try {
    await query(`SELECT * FROM set_page_matched($1);`, [pageid]);
  } catch (err) {
    console.error(`Error in setPageMatched for pageid ${pageid}:`, err);
    throw err;
  }
};
