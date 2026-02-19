import { query } from "./wikipool";

export default async (pageIds: number[], cultureId: number, title: string) => {
  console.log("🚀 ~ cultureId:", cultureId);
  console.log("🚀 ~ pageIds:", pageIds);
  await query("SELECT * FROM set_page_culture_bridge_batch($1, $2, $3)", [
    cultureId,
    pageIds,
    title,
  ]);
  console.log(`✅ Culture set for ${pageIds.length} pages to "${cultureId}".`);
};
