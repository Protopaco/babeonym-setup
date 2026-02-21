export default (infoBox: any): string | null => {
  // const sections = documentJson?.sections ?? [];
  // console.log("🚀 ~ sections:", sections);
  // const leadSection =
  // sections.find((section: any) => (section?.title ?? "") === "") ??
  // sections[0];
  // console.log("🚀 ~ leadSection:", leadSection);

  // const infoboxes = leadSection?.infoboxes ?? [];
  const firstInfobox = infoBox[0];
  // console.log("🚀 ~ infoBox:", firstInfobox);
  // console.log("typeof infoBox", typeof infoBox);
  // console.log("🚀 ~ infoBox.meaning:", firstInfobox?.meaning);
  // console.log("🚀 ~ typeof infoBox.meaning:", typeof firstInfobox?.meaning);
  if (!infoBox) return null;

  const meaningField = firstInfobox?.meaning;
  // console.log("🚀 ~ meaningField:", meaningField);
  const rawMeaningText = (meaningField?.text ?? "").trim();
  // console.log("🚀 ~ rawMeaningText:", rawMeaningText);

  if (!rawMeaningText) return null;

  // Normalize common Wikipedia quoting/formatting artifacts
  const normalizedMeaning = rawMeaningText
    .replace(/^\s*["“”]+/, "")
    .replace(/["“”]+\s*$/, "")
    .replace(/\s+/g, " ")
    .trim();
  // console.log("🚀 ~ normalizedMeaning:", normalizedMeaning);

  return normalizedMeaning.length > 0 ? normalizedMeaning : null;
};
