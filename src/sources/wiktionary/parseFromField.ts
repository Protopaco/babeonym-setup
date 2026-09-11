export type FromFieldEntry = {
  /**
   * The origin as a language name. When the origin is written as a code and a
   * term ("de:Elisabeth") this is Wiktionary's canonical name for the code
   * ("German"); otherwise it is the token exactly as written ("Ancient Greek",
   * "surnames").
   */
  language: string;
  /**
   * True for a language the name merely passed through. "Latin < Ancient Greek
   * < Hebrew" reads as "from Latin, which took it from Ancient Greek, which
   * took it from Hebrew" — Latin is the proximate source, Hebrew the ultimate
   * origin, and Ancient Greek is transit.
   */
  isTransmission: boolean;
  /** The Wiktionary language code, when the origin was written as code:term. */
  code: string | null;
  /** The source term with link markup removed — "Elisabeth" in de:Elisabeth. */
  term: string | null;
  /** The inline <t:...> gloss on the source term, when one was given. */
  gloss: string | null;
};

/**
 * An inline modifier such as <t:bear> or <tr:gaḇrīʾḗl>. The key is always
 * lowercase letters followed by a colon, and there is never a space after the
 * "<" — which is what tells it apart from the " < " chain separator.
 */
const MODIFIER_OPENING = /^<[a-z]+:/;
const MODIFIER = /<([a-z]+):([^<>]*)>/g;

/**
 * A two- or three-letter lowercase base, then optional segments of either case:
 * grc-koi, en-US, de-AT-vie, cmn-wadegiles. Matching the shape only nominates a
 * code — it still has to exist in Wiktionary's table to be read as one.
 *
 * {{ety}} writes its terms the same way, so the meaning extractor reads them
 * with this too.
 */
export const CODE_AND_TERM = /^([a-z]{2,3}(?:-[A-Za-z]{2,9})*):(.+)$/;

/** Wiktionary's template documentation requires the spaces. */
const CHAIN_SEPARATOR = " < ";
const LIST_SEPARATOR = ",";

/**
 * Splits on a separator, skipping any occurrence inside an inline modifier.
 * Glosses can carry commas — <t:to choose, wish, want> — and a plain split cuts
 * the gloss in half and reads each piece as a language.
 */
const splitOutsideModifiers = (text: string, separator: string) => {
  const parts: string[] = [];
  let modifierDepth = 0;
  let currentPart = "";

  for (let index = 0; index < text.length; index++) {
    if (text[index] === "<" && MODIFIER_OPENING.test(text.slice(index))) {
      modifierDepth++;
    } else if (text[index] === ">" && modifierDepth > 0) {
      modifierDepth--;
    }

    if (modifierDepth === 0 && text.startsWith(separator, index)) {
      parts.push(currentPart);
      currentPart = "";
      index += separator.length - 1;
      continue;
    }

    currentPart += text[index];
  }

  parts.push(currentPart);
  return parts.map((part) => part.trim()).filter((part) => part.length > 0);
};

const removeLinkMarkup = (text: string) =>
  text
    .replace(/\[\[([^\]|]*)\|([^\]]*)\]\]/g, "$2")
    .replace(/\[\[([^\]]*)\]\]/g, "$1")
    .trim();

/**
 * Reads the from= field of {{given name}}, following Wiktionary's documentation
 * for it: a comma-separated list of sources, each either a language name or a
 * language code and term ("de:Ulrich"), with inline modifiers attached to terms
 * and " < " walking a chain of derivation.
 *
 * The previous version split on a bare "<", which also cut through the inline
 * modifiers — so from=la:Renātus<t:reborn> came out as two "languages",
 * "la:Renātus" and "t:reborn>".
 */
export default (
  fromFieldValue: string,
  canonicalNameByCode: Map<string, string>,
): FromFieldEntry[] => {
  const entries: FromFieldEntry[] = [];

  for (const listItem of splitOutsideModifiers(fromFieldValue, LIST_SEPARATOR)) {
    const chain = splitOutsideModifiers(listItem, CHAIN_SEPARATOR)
      .map((element) => {
        let gloss: string | null = null;

        for (const modifier of element.matchAll(MODIFIER)) {
          if (modifier[1] === "t" && modifier[2].trim().length > 0) {
            gloss = modifier[2].trim();
          }
        }

        return { gloss, source: element.replace(MODIFIER, "").trim() };
      })
      .filter((element) => element.source.length > 0);

    chain.forEach((element, chainIndex) => {
      const codeAndTerm = element.source.match(CODE_AND_TERM);
      const canonicalName = codeAndTerm
        ? canonicalNameByCode.get(codeAndTerm[1])
        : undefined;

      entries.push({
        // An unrecognised code keeps its raw text, so it lands in the review
        // queue where it can be seen rather than disappearing.
        language: canonicalName ?? element.source,
        isTransmission: chainIndex > 0 && chainIndex < chain.length - 1,
        code: canonicalName && codeAndTerm ? codeAndTerm[1] : null,
        term:
          canonicalName && codeAndTerm ? removeLinkMarkup(codeAndTerm[2]) : null,
        gloss: element.gloss,
      });
    });
  }

  return entries;
};
