type WikiCmMember = {
  pageid: number;
  ns: number;
  title: string;
};

type WikiCmResponse = {
  continue?: { cmcontinue: string; continue: string };
  query?: { categorymembers?: WikiCmMember[] };
};

type GetAllSubcategoriesOpts = {
  apiUrl: string;
  categoryTitle: string;
  maxDepth?: number; // default: 10
  limitPerRequest?: 50 | 100 | 250 | 500; // default: 500
};

type SubcategoryResult = {
  pageid: number;
  title: string;
};

const normalizeCategoryTitle = (t: string) =>
  t.startsWith("Category:") ? t : `Category:${t}`;

const fetchCategoryMembersPage = async (
  apiUrl: string,
  params: Record<string, string>,
) => {
  const url = new URL(apiUrl);
  Object.entries(params).forEach(([k, v]) => url.searchParams.set(k, v));

  const res = await fetch(url.toString());
  if (!res.ok) {
    throw new Error(`Wikipedia API error: ${res.status} ${res.statusText}`);
  }

  return (await res.json()) as WikiCmResponse;
};

/**
 * Recursively collects all subcategories under a category.
 * - Traverses ns=14 only
 * - Returns pageid + title
 * - Handles pagination
 * - Prevents cycles
 */
const getAllSubcategories = async (
  opts: GetAllSubcategoriesOpts,
): Promise<SubcategoryResult[]> => {
  const { apiUrl, categoryTitle, maxDepth = 10, limitPerRequest = 500 } = opts;

  const root = normalizeCategoryTitle(categoryTitle);

  const visitedCategories = new Set<string>();
  const subcategories = new Map<number, SubcategoryResult>();

  const walk = async (catTitle: string, depth: number): Promise<void> => {
    if (depth > maxDepth) return;
    if (visitedCategories.has(catTitle)) return;

    visitedCategories.add(catTitle);

    let cmcontinue: string | undefined;

    while (true) {
      await new Promise((resolve) => setTimeout(resolve, 2000)); // small delay to be polite to Wikipedia servers
      const data = await fetchCategoryMembersPage(apiUrl, {
        action: "query",
        list: "categorymembers",
        cmtitle: catTitle,
        cmtype: "subcat",
        cmlimit: String(limitPerRequest),
        format: "json",
        origin: "*",
        ...(cmcontinue ? { cmcontinue } : {}),
      });

      const members = data.query?.categorymembers ?? [];
      console.log("🚀 ~ walk ~ members:", members);

      for (const m of members) {
        if (m.ns !== 14) continue;

        if (!subcategories.has(m.pageid)) {
          subcategories.set(m.pageid, {
            pageid: m.pageid,
            title: m.title,
          });
        }

        await walk(m.title, depth + 1);
      }

      cmcontinue = data.continue?.cmcontinue;
      if (!cmcontinue) break;
    }
  };

  await walk(root, 0);

  return [...subcategories.values()];
};

export default getAllSubcategories;
