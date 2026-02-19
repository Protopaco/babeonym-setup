import { get } from "node:http";
import categoryCulturePairs from "./data/categoryCulturePairs";
import setPageCultureBridge from "./db/setPageCultureBridge";
import getCategoryTitleFromPageId from "./db/getCategoryTitleFromPageId";
import fetchAllCategoryPageids from "./fetchAllCategoryPageids";

export default async () => {
  console.log(
    "\n→ Setting up page-culture bridge for given name categories...",
  );
  for await (const pair of categoryCulturePairs) {
    console.log("🚀 ~ pair:", pair);

    if (!pair.label || !pair.cultureId || !pair.pageids) {
      console.warn(
        `Skipping invalid category-culture pair: ${JSON.stringify(pair)}`,
      );
      continue;
    }
    for await (const pageid of pair.pageids) {
      console.log("🚀 ~ pageid:", pageid);
      const categoryTitle = await getCategoryTitleFromPageId(pageid);
      if (!categoryTitle) {
        console.warn(
          `No category title found for page ID ${pageid}. Skipping...`,
        );
        continue;
      }
      const members = await fetchAllCategoryPageids({
        apiUrl: "https://en.wikipedia.org/w/api.php",
        categoryTitle: categoryTitle,
        includeNamespaces: [0], // articles only
        limitPerRequest: 500,
      });
      console.log(
        `Fetched ${members.length} pages for category "${pair.label}" with culture ID ${pair.cultureId}`,
      );

      await setPageCultureBridge(members, pair.cultureId, pair.label);
    }
    //break;
  }
};
