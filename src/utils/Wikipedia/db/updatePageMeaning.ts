import { query } from "./wikipool";

export default async (
  pageid: number,
  shortMeaning: string | null,
  longMeaning: string | null,
): Promise<void> => {
  await query("SELECT update_page_meaning($1, $2, $3)", [
    pageid,
    shortMeaning,
    longMeaning,
  ]);
};
