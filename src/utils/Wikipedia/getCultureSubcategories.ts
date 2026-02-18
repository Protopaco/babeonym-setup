import setTempCulturePage from "./db/setTempCulturePage";
import fetchAllCategorySubcategories from "./fetchAllCategorySubcategories";

export default async (categoryTitle: string) => {
  console.log(`\n→ Fetching subcategories for category: ${categoryTitle}...`);
  const subcategories = await fetchAllCategorySubcategories({
    apiUrl: "https://en.wikipedia.org/w/api.php",
    categoryTitle: categoryTitle,
    maxDepth: 5, // articles only
    limitPerRequest: 500,
  });
  console.log("🚀 ~ subcategories.length:", subcategories.length);

  for await (const subcat of subcategories) {
    console.log("🚀 ~ subcat:", subcat);
    await setTempCulturePage(subcat.pageid, subcat.title);
  }
};
