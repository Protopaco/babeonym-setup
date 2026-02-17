import { query } from "./wikipool";

export default async (pageIds: number[], languageId: number, title: string) => {
  console.log("🚀 ~ languageId:", languageId);
  console.log("🚀 ~ pageIds:", pageIds);
  await query("SELECT * FROM set_page_language_bridge_batch($1, $2, $3)", [
    languageId,
    pageIds,
    title,
  ]);
  console.log(
    `✅ Language set for ${pageIds.length} pages to "${languageId}".`,
  );
};
