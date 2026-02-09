import setWikipediaPageIdsBulk from "./db/setWikipediaPageIdsBulk";
import wikipediaClient from "./wikipediaClient";

export default async (categoryTitle: string) => {
  const queryParams = {
    action: "query",
    list: "categorymembers",
    cmtitle: `Category:${categoryTitle}`,
    cmtype: "page",
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

  const members = firstResponse.query.categorymembers;

  const totalMembers = members.length;
  console.log("🚀 ~ totalMembers:", totalMembers);
  let cmcontinue = firstResponse.continue
    ? firstResponse.continue.cmcontinue
    : null;
  await setWikipediaPageIdsBulk(members, categoryTitle); // Save the first batch of members to the database
  while (cmcontinue) {
    await new Promise((resolve) => setTimeout(resolve, 1000)); // Add a small delay to avoid hitting rate limits
    const nextQueryParams = {
      ...queryParams,
      cmcontinue,
    };
    const nextResponse = await wikipediaClient(nextQueryParams);
    if (
      !nextResponse ||
      !nextResponse.query ||
      !nextResponse.query.categorymembers
    ) {
      console.error(
        "Invalid response from Wikipedia API during pagination:",
        nextResponse,
      );
      break;
    }
    const nextMembers = nextResponse.query.categorymembers;
    const totalMembers = members.length;
    console.log("🚀 ~ totalMembers:", totalMembers);
    await setWikipediaPageIdsBulk(nextMembers, categoryTitle);

    cmcontinue = nextResponse.continue
      ? nextResponse.continue.cmcontinue
      : null;
  }

  console.log(
    `Fetched ${members.length} members of category "${categoryTitle}" (initial: ${totalMembers})`,
  );
  return members;
};
