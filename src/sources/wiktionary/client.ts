import fetchWithRetry from "../fetchWithRetry";
import getWikimediaUserAgent from "../getWikimediaUserAgent";

type WiktionaryRevision = {
  slots?: {
    main?: {
      content?: string;
    };
  };
};

type WiktionaryPage = {
  pageid?: number;
  ns?: number;
  title: string;
  missing?: boolean;
  revisions?: WiktionaryRevision[];
};

type TitleMapping = {
  from: string;
  to: string;
};

type WiktionaryResponse = {
  query?: {
    pages?: WiktionaryPage[];
    normalized?: TitleMapping[];
    redirects?: TitleMapping[];
  };
};

export type WiktionaryEntry = {
  requestedTitle: string;
  resolvedTitle: string;
  url: string;
  /** Page object with the revision content removed — rawText already holds it. */
  rawPayload: unknown;
  rawText: string | null;
  exists: boolean;
};

/** The API returns full wikitext for up to this many titles in one request. */
export const WIKTIONARY_TITLES_PER_REQUEST = 50;

const WIKTIONARY_API_URL = "https://en.wiktionary.org/w/api.php";

/**
 * A requested title can be rewritten twice before it reaches a page: once by
 * normalisation (case and underscores) and again by a redirect. Following both
 * chains is what lets the caller key results by the title it asked for.
 */
const resolveRequestedTitle = (
  requestedTitle: string,
  response: WiktionaryResponse,
) => {
  const applyMappings = (title: string, mappings: TitleMapping[] = []) => {
    return mappings.find((mapping) => mapping.from === title)?.to ?? title;
  };

  const normalisedTitle = applyMappings(
    requestedTitle,
    response.query?.normalized,
  );

  return applyMappings(normalisedTitle, response.query?.redirects);
};

const stripRevisionContent = (page: WiktionaryPage) => {
  const { revisions, ...pageWithoutRevisions } = page;
  return pageWithoutRevisions;
};

export default async (
  titles: string[],
): Promise<Map<string, WiktionaryEntry>> => {
  if (titles.length === 0) {
    return new Map();
  }

  if (titles.length > WIKTIONARY_TITLES_PER_REQUEST) {
    throw new Error(
      `Wiktionary accepts at most ${WIKTIONARY_TITLES_PER_REQUEST} titles per request, received ${titles.length}.`,
    );
  }

  const params = new URLSearchParams({
    action: "query",
    prop: "revisions",
    redirects: "1",
    rvprop: "content",
    rvslots: "main",
    titles: titles.join("|"),
    format: "json",
    formatversion: "2",
  });

  const response = await fetchWithRetry(
    `${WIKTIONARY_API_URL}?${params.toString()}`,
    {
      headers: {
        "User-Agent": getWikimediaUserAgent(),
        "Accept-Encoding": "gzip",
      },
    },
  );

  const rawPayload = (await response.json()) as WiktionaryResponse;
  const pagesByTitle = new Map<string, WiktionaryPage>(
    (rawPayload.query?.pages ?? []).map((page) => [page.title, page]),
  );

  const entries = new Map<string, WiktionaryEntry>();

  for (const requestedTitle of titles) {
    const resolvedTitle = resolveRequestedTitle(requestedTitle, rawPayload);
    const page = pagesByTitle.get(resolvedTitle);

    entries.set(requestedTitle, {
      requestedTitle,
      resolvedTitle,
      url: `https://en.wiktionary.org/wiki/${encodeURIComponent(resolvedTitle)}`,
      rawPayload: page ? stripRevisionContent(page) : null,
      rawText: page?.revisions?.[0]?.slots?.main?.content ?? null,
      exists: Boolean(page && !page.missing),
    });
  }

  return entries;
};
