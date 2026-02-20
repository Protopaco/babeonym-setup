import { query } from "./wikipool";

export default async (pageid: number, title: string): Promise<void> => {
  try {
    await query(
      `INSERT INTO titles_without_matches (pageid, title) VALUES ($1, $2) ON CONFLICT (pageid) DO NOTHING;`,
      [pageid, title],
    );
  } catch (err) {
    console.error(
      `Error in setTitleWithoutMatch for pageid ${pageid} and title ${title}:`,
      err,
    );
    throw err;
  }
};
