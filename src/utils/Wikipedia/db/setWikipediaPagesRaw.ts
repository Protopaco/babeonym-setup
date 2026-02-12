import RawPage from "../models/RawPage";
import { query } from "./wikipool";

const asObj = (v: any) => (typeof v === "string" ? JSON.parse(v) : v);

export default async (
  requestedPageId: number,
  resolvedPageId: number,
  resolvedTitle: string | null,
  infobox_json: any,
  sections_json: any,
  categories: string[],
  text: string,
  wtf_json: any,
) => {
  console.log("setWikipediaPagesRaw - resolvedPageId:", resolvedPageId);
  try {
    await query(
      "SELECT set_wikipedia_page_raw($1, $2, $3, $4::jsonb, $5::jsonb, $6::text[], $7::text, $8::jsonb)",
      [
        requestedPageId,
        resolvedPageId,
        resolvedTitle,
        JSON.stringify(infobox_json),
        JSON.stringify(sections_json),
        categories,
        text,
        JSON.stringify(wtf_json),
      ],
    );
  } catch (error) {
    console.error("Error in setWikipediaPagesRaw:", error);
  }
};
