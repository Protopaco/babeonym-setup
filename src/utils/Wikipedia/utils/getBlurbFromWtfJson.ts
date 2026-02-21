const buildParagraphText = (paragraph: any): string => {
  const sentences = paragraph?.sentences ?? [];

  return sentences
    .map((sentence: any) => (sentence?.text ?? "").trim())
    .filter((text: string) => text.length > 0)
    .join(" ")
    .trim();
};

const isUnusableLeadParagraph = (paragraphText: string): boolean => {
  const normalized = paragraphText.trim().toLowerCase();

  if (normalized.length < 40) return true;

  return (
    normalized.includes("may refer to") ||
    normalized.includes("may also refer to") ||
    normalized.startsWith("for other uses") ||
    normalized.startsWith("this article is about") ||
    normalized.startsWith("not to be confused with") ||
    normalized.startsWith("for the meaning of the name") ||
    normalized.includes("name include:")
  );
};

export default (documentJson: any): string | null => {
  if (documentJson?.isDisambiguation) return null;

  const sections = documentJson?.sections ?? [];

  const leadSection = sections.find(
    (section: any) => (section?.title ?? "") === "",
  );

  if (!leadSection) return null;

  const paragraphs = (leadSection?.paragraphs ?? [])
    .map(buildParagraphText)
    .filter((text: string) => text.length > 0);

  const firstValidParagraph = paragraphs.find(
    (paragraphText: string) => !isUnusableLeadParagraph(paragraphText),
  );

  return firstValidParagraph ?? null;
};
