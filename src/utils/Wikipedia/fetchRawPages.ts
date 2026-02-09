import getWikipediaPagesToFetch from "./db/getWikipediaPagesToFetch";
import setWikipediaPagesRaw from "./db/setWikipediaPagesRaw";
import wikipediaClient from "./wikipediaClient";

export default async (numberOfFetches: number = 1) => {
  for (let i = 0; i < numberOfFetches; i++) {
    await new Promise((resolve) => setTimeout(resolve, 1000));
    const pagesToFetch = await getWikipediaPagesToFetch(20, 1);
    console.log("🚀 ~ pagesToFetch:", pagesToFetch);
    const params = {
      action: "query",
      prop: "revisions",
      rvprop: "content",
      rvslots: "main",
      pageids: pagesToFetch.join("|"),
      format: "json",
    };
    const response = await wikipediaClient(params);

    const pageData = Object.values(response.query.pages).map((page: any) => {
      return {
        pageid: page.pageid,
        raw_content: JSON.stringify(page.revisions),
      };
    });
    await setWikipediaPagesRaw(pageData);
  }
};
