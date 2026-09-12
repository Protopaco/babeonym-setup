const MAXIMUM_PHRASE_LENGTH = 25;

/**
 * Several senses arrive in one string — "Girl, Woman", "female child, girl,
 * maiden" — and each is a meaning in its own right. Splitting on these three
 * separators turns 26-to-40 character strings, which look like long meanings,
 * into two or three short ones: 98% of Wiktionary phrases and 79% of the older
 * Wikipedia phrases land inside the length limit afterwards.
 */
const PHRASE_SEPARATORS = /\s*(?:[,;]|\bor\b)\s*/;

const SMART_QUOTE_REPLACEMENTS: [RegExp, string][] = [
  [/[“”]/g, '"'],
  [/[‘’]/g, "'"],
];

/**
 * The older scrape lost its opening quotes, leaving strings like
 * `to honour" or "to esteem` — 400 of them. Removing quote characters outright
 * is safer than trying to pair them up, since a meaning never needs one.
 */
const STRAY_QUOTE = /"/g;

/**
 * Commentary that survives the length limit because it is short. All of these
 * describe a name rather than state a meaning, and they are the difference
 * between a meaning list and a pile of cross-references.
 */
const COMMENTARY_PATTERNS = [
  /^(?:a |an |the )?(?:form|variant|version|diminutive|equivalent|spelling|derivative|combination|short form|name|given name|feminine|masculine)\b/,
  /^(?:from|after|taken from|used|meaning|see|also|possibly|probably|unknown|uncertain|disputed|various)\b/,
  // "male given name" and "female given name" arrive as the meaning itself,
  // which states the part of speech rather than what the name means. Matching
  // on "given name" instead of on male/female keeps real meanings built from
  // those words, such as "female warrior".
  /\b(?:of the name|equivalent of|form of|variant of|given names?)\b/,
];

const isCommentary = (phrase: string) =>
  COMMENTARY_PATTERNS.some((pattern) => pattern.test(phrase));

/**
 * A phrase that only points at another name — "son of Alexander", "descendant
 * of Caiside" — tells a reader nothing, because the meaning lives in the name
 * being pointed at rather than in the phrase. Patronymic names lose their only
 * meaning this way, and showing nothing is the honest result: Bowen means "son
 * of Owen", which answers the question with the question.
 *
 * The capital is what separates those from real meanings built on the same
 * words, so this is tested before the phrase is lowercased. Benjamin's "son of
 * the right hand" and Bathsheba's "daughter of an oath" stay.
 *
 * Resolving the name pointed at — Owen, Rian, Talmai each have a meaning of
 * their own — is a later job, and the claims keep their evidence for it.
 */
const NAME_REFERENCE =
  /^(?:son|daughter|child|grandson|granddaughter|grandchild|descendant)s? of (?:\(?a person named\)? )?[A-Z]/;

/**
 * The same fault without the relation word: a gloss that is one capitalised
 * word is a name rather than a meaning. Kadi is glossed "Catherine", Sasha
 * "Alexander", Merle "Muriel" — each answers the question with another name.
 *
 * Only Wiktionary's capitalisation carries the signal. The older Wikipedia
 * scrape is Title Case throughout, where "Lion" is a meaning and not a name, so
 * the caller says whether capitalisation can be read this way.
 */
const BARE_NAME = /^[A-Z][a-zà-öø-ÿ'’-]+$/;

/**
 * Turns one source string into the distinct meaning phrases it contains.
 *
 * Runs over both sources on purpose. The two disagree on nearly everything —
 * casing, quoting, how many senses go in one string — and they only dedupe
 * against each other once put through the same rules.
 *
 * Lowercasing everything is a deliberate first pass rather than the end state.
 * It damages proper nouns, turning "Thor's stone" into "thor's stone", but it
 * is what makes "Jewel" and "jewel" one row instead of two. Restoring capitals
 * is a later pass that reads the untouched source columns, so nothing here has
 * to be right the first time.
 *
 * The name is passed in because a source sometimes gives a name as its own
 * meaning — Gershom means Gershom, and "andrew" appears in both sources.
 */
export type PhraseDropReason =
  | "empty"
  | "too_long"
  | "same_as_name"
  | "commentary"
  | "points_at_a_name"
  | "duplicate";

export type NormalisedPhrases = {
  phrases: string[];
  dropped: { phrase: string; reason: PhraseDropReason }[];
};

export default (
  rawText: string,
  givenName: string,
  capitalisationIsMeaningful = false,
): NormalisedPhrases => {
  let workingText = rawText;

  for (const [pattern, replacement] of SMART_QUOTE_REPLACEMENTS) {
    workingText = workingText.replace(pattern, replacement);
  }

  workingText = workingText.replace(STRAY_QUOTE, " ");

  const seenPhrases = new Set<string>();
  const phrases: string[] = [];
  const dropped: NormalisedPhrases["dropped"] = [];
  const lowerCasedName = givenName.trim().toLowerCase();

  for (const candidate of workingText.split(PHRASE_SEPARATORS)) {
    // Kept as the source wrote it until the checks are done, since one of them
    // reads the capital that lowercasing would remove.
    const writtenPhrase = candidate
      .replace(/\s+/g, " ")
      .trim()
      .replace(/^[.'"]+|[.'"]+$/g, "")
      .trim();

    const phrase = writtenPhrase.toLowerCase();

    const reason: PhraseDropReason | null =
      phrase.length === 0
        ? "empty"
        : phrase.length > MAXIMUM_PHRASE_LENGTH
          ? "too_long"
          : phrase === lowerCasedName
            ? "same_as_name"
            : isCommentary(phrase)
              ? "commentary"
              : NAME_REFERENCE.test(writtenPhrase) ||
                  (capitalisationIsMeaningful && BARE_NAME.test(writtenPhrase))
                ? "points_at_a_name"
                : seenPhrases.has(phrase)
                  ? "duplicate"
                  : null;

    if (reason !== null) {
      // An empty fragment is an artefact of splitting, not a judgment about the
      // source, so it is not worth reporting as a drop.
      if (reason !== "empty") {
        dropped.push({ phrase, reason });
      }
      continue;
    }

    seenPhrases.add(phrase);
    phrases.push(phrase);
  }

  return { phrases, dropped };
};
