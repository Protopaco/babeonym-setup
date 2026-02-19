import categoryLanguagePairs from "./data/categoryLanguagePairs";
import setPageLanguageBridge from "./db/setPageLanguageBridge";
import fetchAllCategoryPageids from "./fetchAllCategoryPageids";

export default async () => {
  console.log(
    "\n→ Setting up page-language bridge for given name categories...",
  );
  for await (const pair of categoryLanguagePairs) {
    if (!pair.title || !pair.languageid || !pair.languagelabel) {
      console.warn(
        `Skipping invalid category-language pair: ${JSON.stringify(pair)}`,
      );
      continue;
    }
    const members = await fetchAllCategoryPageids({
      apiUrl: "https://en.wikipedia.org/w/api.php",
      categoryTitle: pair.title,
      includeNamespaces: [0], // articles only
      limitPerRequest: 500,
    });
    console.log(
      `Fetched ${members.length} pages for category "${pair.title}" with language ID ${pair.languagelabel}`,
    );
    // Here you would typically call a function to save these page-language pairs to your database
    // For example: await setPageLanguageBridgeBulk(members, pair.languageId);
    await setPageLanguageBridge(members, pair.languageid, pair.title);
    //break;
  }
};
