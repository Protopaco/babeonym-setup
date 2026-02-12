import getWikipediaPagesToFetch from "./db/getWikipediaPagesToFetch";
import wtf from "wtf_wikipedia";
import setWikipediaPagesRaw from "./db/setWikipediaPagesRaw";
wtf.extend(require("wtf-plugin-api"));

export default async () => {
  const pageIds = await getWikipediaPagesToFetch(1, 1);

  for (const requestedPageId of pageIds) {
    const page = await wtf.fetch(requestedPageId, { follow_redirects: true });
    if (!page) {
      console.error("No page found for pageId:", requestedPageId);
      continue;
    }
    const resolvedPageId = page.pageID();
    if (!resolvedPageId) {
      console.error("Page without pageID, skipping:", page);
      continue;
    }
    const infoboxes = page.infoboxes().map((infobox: any) => infobox.json());
    const sections = page.sections().map((s: any) => ({
      title: s.title(),
      depth: s.depth?.() ?? null,
    }));
    const categories = page.categories();
    const text = page.text();
    const wtfJson = page.json();
    const resolvedTitle = page.title();

    await setWikipediaPagesRaw(
      requestedPageId,
      resolvedPageId,
      resolvedTitle,
      infoboxes,
      sections,
      categories,
      text,
      wtfJson,
    );
  }
  //   result.sentences().forEach((s) => console.log("🚀 ~ sentence:", s.text()));
  //console.log("🚀 ~ json:", result.sentences()[0].text());
  //console.log("🚀 ~ result:", result);
};
