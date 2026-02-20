import getGivenName from "./db/getGivenName";
import getUnbridgedPageidsWithTitle from "./db/getUnbridgedPageidsWithTitle";
import setPageGivenNameBridge from "./db/setPageGivenNameBridge";
import setPageMatched from "./db/setPageMatched";
import setTitleWithoutMatch from "./db/setTitleWithoutMatch";

export default async () => {
  const unbridgedPageInfos = await getUnbridgedPageidsWithTitle(10000);
  //   console.log("🚀 ~ unbridgedPageInfos:", unbridgedPageInfos);
  let pageCount = 0;
  let matchFound = 0;

  for (const pageInfo of unbridgedPageInfos) {
    const { pageid, title, resolved_title, resolved_pageid } = pageInfo;
    pageCount++;
    if (resolved_title && resolved_pageid) {
      const normalizedResolvedTitle = normalizeTitle(resolved_title);

      const resolvedGivenName = await getGivenName(normalizedResolvedTitle);
      //console.log("🚀 ~ resolvedGivenName:", resolvedGivenName);
      if (resolvedGivenName) {
        await setPageGivenNameBridge(pageid, resolvedGivenName.id);
        console.log(
          `😣 Bridged pageid ${pageid} with given name ${resolvedGivenName.givenName} from resolved title ${resolved_title}`,
        );
        continue; // Move to the next pageInfo
      } else {
        await setPageMatched(pageid);
        await setTitleWithoutMatch(pageid, normalizedResolvedTitle);
        console.log(
          `🚫 No given name found for resolved title ${normalizedResolvedTitle} of pageid ${pageid}`,
        );
      }
    } else {
      const normalizedTitle = normalizeTitle(title);

      const givenNameMatch = await getGivenName(normalizedTitle);
      console.log("🚀 ~ givenNameMatch:", givenNameMatch);
      if (givenNameMatch) {
        await setPageGivenNameBridge(pageInfo.pageid, givenNameMatch.id);
        console.log(
          ` 🙌 Bridged pageid ${pageInfo.pageid} with given name ${givenNameMatch.givenName}`,
        );
        matchFound++;
      } else {
        await setPageMatched(pageid);
        await setTitleWithoutMatch(pageid, normalizedTitle);
        console.log(
          `🚫 No given name found for pageid ${pageInfo.pageid} with title ${normalizedTitle}`,
        );
      }
    }
    if (pageCount % 100 === 0) {
      console.log(
        `Progress: ${pageCount}/${unbridgedPageInfos.length} pages processed, ${matchFound} matches found.`,
      );
    }
  }
};

const normalizeTitle = (title: string) => {
  return title
    .toLowerCase()
    .split("(")[0]
    .replace(/\s*\(.*?\)\s*/g, " ") // drop parentheticals
    .normalize("NFKD") // split accents
    .replace(/[\u0300-\u036f]/g, "") // remove diacritic marks
    .replace(/[^a-z]/g, "");
};
