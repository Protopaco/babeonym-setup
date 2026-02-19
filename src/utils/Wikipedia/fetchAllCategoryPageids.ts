type WikiCmMember = {
  pageid: number;
  ns: number;
  title: string;
};

type WikiCmResponse = {
  continue?: { cmcontinue: string; continue: string };
  query?: { categorymembers?: WikiCmMember[] };
};

type GetAllCategoryPageIdsOpts = {
  apiUrl: string; // e.g. "https://en.wikipedia.org/w/api.php"
  categoryTitle: string; // e.g. "American male actors" OR "Category:American male actors"
  includeNamespaces?: number[]; // default: [0] (mainspace only)
  maxDepth?: number; // default: Infinity
  limitPerRequest?: 50 | 100 | 250 | 500; // default: 500
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
  if (!res.ok)
    throw new Error(`Wikipedia API error: ${res.status} ${res.statusText}`);
  return (await res.json()) as WikiCmResponse;
};

/**
 * Recursively collects pageids for all pages in a category tree.
 * - Traverses subcategories (ns=14)
 * - Collects pages in `includeNamespaces` (default: ns=0 only)
 * - Handles pagination (`cmcontinue`)
 * - Prevents cycles via `visitedCategories`
 */
const getAllCategoryPageIds = async (
  opts: GetAllCategoryPageIdsOpts,
): Promise<number[]> => {
  const {
    apiUrl,
    categoryTitle,
    includeNamespaces = [0],
    maxDepth = 10,
    limitPerRequest = 500,
  } = opts;

  const root = normalizeCategoryTitle(categoryTitle);

  const visitedCategories = new Set<string>();
  const pageIds = new Set<number>();

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
        cmtype: "page|subcat",
        cmlimit: String(limitPerRequest),
        format: "json",
        origin: "*",
        ...(cmcontinue ? { cmcontinue } : {}),
      });

      const members = data.query?.categorymembers ?? [];
      console.log("🚀 ~ walk ~ members:", members);
      console.log(
        `Fetched ${members.length} members for category "${catTitle}" at depth ${depth}.`,
      );

      for (const m of members) {
        if (m.ns === 14) {
          // subcategory
          console.log("SUBCAT:", m.title);
          await walk(m.title, depth + 1);
          continue;
        }

        // regular page (or other namespace)
        if (includeNamespaces.includes(m.ns)) pageIds.add(m.pageid);
      }

      cmcontinue = data.continue?.cmcontinue;
      if (!cmcontinue) break;
    }
  };

  await walk(root, 0);
  return [...pageIds];
};

export default getAllCategoryPageIds;
