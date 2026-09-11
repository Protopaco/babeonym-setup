import fetchWithRetry from "../fetchWithRetry";
import getWikimediaUserAgent from "../getWikimediaUserAgent";

const WIKTIONARY_INDEX_URL = "https://en.wiktionary.org/w/index.php";

/** One entry per line in the module: ["grc"] = "Ancient Greek", */
const CODE_ENTRY = /\["([^"]+)"\]\s*=\s*"([^"]*)"/g;

/**
 * Reads one of Wiktionary's code-to-name data modules as raw Lua source.
 *
 * Using the published module rather than a hand-built list keeps the codes in
 * step with the names Wiktionary writes everywhere else, and there are nearly
 * nine thousand of them.
 */
export default async (moduleTitle: string) => {
  const parameters = new URLSearchParams({ title: moduleTitle, action: "raw" });

  const response = await fetchWithRetry(
    `${WIKTIONARY_INDEX_URL}?${parameters.toString()}`,
    { headers: { "User-Agent": getWikimediaUserAgent() } },
  );

  const moduleSource = await response.text();
  const entries = [...moduleSource.matchAll(CODE_ENTRY)].map((match) => ({
    code: match[1],
    canonicalName: match[2],
  }));

  // An empty result means the module changed shape, not that Wiktionary has no
  // languages. Failing loudly beats silently emptying the table.
  if (entries.length === 0) {
    throw new Error(
      `No language codes found in ${moduleTitle}. The module format may have changed.`,
    );
  }

  return entries;
};
