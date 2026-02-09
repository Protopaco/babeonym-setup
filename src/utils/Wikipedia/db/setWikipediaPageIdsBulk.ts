import { query } from "./wikipool";
import PageIdDTO from "../models/PageIdDTO";

export default async (rows: PageIdDTO[], source: string) => {
  console.log(`Inserting ${rows.length} page IDs for source "${source}"...`);
  try {
    await query("SELECT * FROM set_wikipedia_page_ids_bulk($1, $2)", [
      JSON.stringify(rows),
      source,
    ]);
  } catch (error) {
    console.error("Error inserting page IDs:", error);
  }
};
