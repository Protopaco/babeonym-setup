import RawPage from "../models/RawPage";
import { query } from "./wikipool";

export default async (pageData: RawPage[]) => {
  console.log("setWikipediaPagesRaw - pageData.length:", pageData.length);
  try {
    await query("SELECT * FROM set_wikipedia_pages_raw($1)", [
      JSON.stringify(pageData),
    ]);
  } catch (error) {
    console.error("Error in setWikipediaPagesRaw:", error);
  }
};
