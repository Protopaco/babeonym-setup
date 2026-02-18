import { query } from "./wikipool";

export default async (pageid: number, rawTitle: string) => {
  console.log(
    `Setting temporary culture page for page ID ${pageid} with title "${rawTitle}"...`,
  );
  await query("SELECT * FROM set_temp_culture_page($1, $2)", [
    pageid,
    rawTitle,
  ]);
  console.log(
    `✅ Temporary culture page set for page ID ${pageid} with title "${rawTitle}".`,
  );
};
