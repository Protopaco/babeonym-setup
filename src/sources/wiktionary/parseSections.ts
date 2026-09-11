export type WikitextSection = {
  /** Heading text, e.g. "English" at level 2, "Etymology 1" at level 3. */
  title: string;
  /** First index of the section body, just past the heading line. */
  contentStartIndex: number;
  /** Index of the next heading at this level, or the end of the page. */
  endIndex: number;
};

/**
 * Splits a page into its headings at one level — level 2 for language sections
 * ("==English=="), level 3 for their subsections ("===Etymology===").
 *
 * Boundaries are computed from the list of matches rather than by looking ahead
 * for the next heading, so a section that runs to the end of the page is still
 * found. Pages where the only language section is last — Siobhan, Dashiell —
 * are the common case, not the edge case.
 */
export default (wikitext: string, headingLevel: number): WikitextSection[] => {
  const equalsSigns = "=".repeat(headingLevel);
  const headingPattern = new RegExp(
    `^${equalsSigns}\\s*([^=\\n][^\\n]*?)\\s*${equalsSigns}\\s*$`,
    "gm",
  );

  const headings: Array<{ title: string; contentStartIndex: number; headingStartIndex: number }> =
    [];

  for (const match of wikitext.matchAll(headingPattern)) {
    headings.push({
      title: match[1].trim(),
      headingStartIndex: match.index,
      contentStartIndex: match.index + match[0].length,
    });
  }

  return headings.map((heading, headingIndex) => ({
    title: heading.title,
    contentStartIndex: heading.contentStartIndex,
    endIndex:
      headings[headingIndex + 1]?.headingStartIndex ?? wikitext.length,
  }));
};
