import wikipediaClient from "./wikipediaClient";
import fetchCategoryMembers from "./fetchCategoryMembers";
import setPageLanguageBridge from "./db/setPageLanguageBridge";
import prompt, { closePrompt } from "./prompt";

export default async (categoryTitle: string) => {
  console.log(`\n→ Fetching subcategories for category: ${categoryTitle}...`);
  const queryParams = {
    action: "query",
    list: "categorymembers",
    cmtitle: `Category:${categoryTitle}`,
    cmtype: "subcat",
    cmlimit: 500,
    format: "json",
    origin: "*",
  };

  const firstResponse = await wikipediaClient(queryParams);
  if (
    !firstResponse ||
    !firstResponse.query ||
    !firstResponse.query.categorymembers
  ) {
    console.error("Invalid response from Wikipedia API:", firstResponse);
    return [];
  }

  const subcategories = firstResponse.query.categorymembers;
  console.log("🚀 ~ subcategories:", subcategories);

  const totalSubcategories = subcategories.length;
  console.log("🚀 ~ totalSubcategories:", totalSubcategories);
  try {
    for await (const subcat of subcategories) {
      console.log("🚀 ~ subcat:", subcat);
      const lanuageId = await prompt(
        `Enter language ID for subcategory "${subcat.title}": `,
      );
      if (
        lanuageId !== null &&
        lanuageId !== undefined &&
        lanuageId !== "" &&
        !isNaN(parseInt(lanuageId))
      ) {
        const pages = await fetchCategoryMembers(subcat.title);
        console.log(
          `Fetched ${pages.length} pages for subcategory "${subcat.title}" with language ID ${lanuageId}`,
        );
        for await (const page of pages) {
          console.log(
            `Processing page "${page.title}" with page ID ${page.pageid} and language ID ${lanuageId}`,
          );
          //await setPageLanguageBridge(page.pageid, parseInt(lanuageId));
        }
      }
    }
  } catch (error) {
    console.error("Error during subcategory processing:", error);
  } finally {
    closePrompt();
  }

  return subcategories;
};
