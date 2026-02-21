import { get } from "node:http";
import getPagesNeedMeanings from "./db/getPagesNeedMeanings";
import getPageRawData from "./db/getPageRawData";
import updatePageMeaning from "./db/updatePageMeaning";
import getInfoboxMeaning from "./utils/getInfoboxMeaning";
import getBlurbFromWtfJson from "./utils/getBlurbFromWtfJson";

export default async () => {
  //get pageIds from get_pages_need_messages
  const pageIds = await getPagesNeedMeanings(10000);
  console.log("🚀 ~ pageIds:", pageIds);

  for await (const pageId of pageIds) {
    console.log("Processing pageId: ", pageId);
    const rawData = await getPageRawData(pageId);
    if (!rawData) {
      console.log(`No raw data found for pageId: ${pageId}`);
      continue;
    }
    //console.log("🚀 ~ rawData.title:", rawData);
    // get short meaning from infobox meaning field
    const shortMeaning = getInfoboxMeaning(rawData.infoboxJson);
    console.log("🚀 ~ shortMeaning:", shortMeaning);
    // get long meaning from first section of page
    const longMeaning = getBlurbFromWtfJson(rawData.wtfJson);
    console.log("🚀 ~ longMeaning:", longMeaning);
    // save to page_meanings table
    await updatePageMeaning(pageId, shortMeaning, longMeaning);
  }
};
