import pool from "../../utils/postGresPool";
import getWikipediaPagesRawToParse from "./db/getWikipediaPagesRawToParse";

export default async () => {
  console.log("\n→ Parsing raw Wikipedia pages...");
  const pages = getWikipediaPagesRawToParse(1);

  for (const page of await pages) {
    console.log(`Parsing pageid ${page.pageid}...`);
    try {
      const infobox = page.infobox_json;
      if (infobox && infobox.length > 0) {
        console.log(`Infobox for pageid ${page.pageid}:`, infobox);
      }
    } catch (error) {
      console.error(`Error parsing infobox for pageid ${page.pageid}:`, error);
    }
  }
};
