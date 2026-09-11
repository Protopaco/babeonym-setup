/**
 * Meaning text arrives wrapped in wiki markup — "[[God]] is [[gracious]]" —
 * and dedup against the meanings table only works if that is stripped first.
 *
 * Casing is deliberately left alone. Lower-casing "who is like God" damages the
 * proper noun, and no rule for that is worth guessing before the comparison
 * report shows whether case-only duplicates actually occur. A trailing question
 * mark is kept for the same reason: it is part of the sense, not stray
 * punctuation.
 */
export default (rawMeaningText: string) => {
  return rawMeaningText
    .replace(/\[\[([^\]|]*)\|([^\]]*)\]\]/g, "$2")
    .replace(/\[\[([^\]]*)\]\]/g, "$1")
    .replace(/\{\{[^{}]*\}\}/g, "")
    .replace(/'''?/g, "")
    .replace(/\s+/g, " ")
    .trim()
    .replace(/[.,;:]+$/, "")
    .trim();
};
