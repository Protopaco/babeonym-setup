export type WikitextTemplate = {
  /** Trimmed and lower-cased, e.g. "given name", "der", "ety". */
  name: string;
  /** Positional arguments in order. Empty slots are preserved as "". */
  positional: string[];
  /** Named arguments, keys trimmed and lower-cased. */
  named: Map<string, string>;
  raw: string;
  startIndex: number;
};

/**
 * Splits template content on the pipes that actually separate arguments —
 * those at depth zero. A pipe inside a nested template or inside a wiki link
 * ("[[wisdom|wise]]") is part of the value, not a separator.
 */
const splitArgumentsAtTopLevel = (content: string) => {
  const argumentParts: string[] = [];
  let currentPart = "";
  let templateDepth = 0;
  let linkDepth = 0;
  let index = 0;

  while (index < content.length) {
    const pair = content.slice(index, index + 2);

    if (pair === "{{") {
      templateDepth++;
      currentPart += pair;
      index += 2;
      continue;
    }

    if (pair === "}}") {
      templateDepth--;
      currentPart += pair;
      index += 2;
      continue;
    }

    if (pair === "[[") {
      linkDepth++;
      currentPart += pair;
      index += 2;
      continue;
    }

    if (pair === "]]") {
      linkDepth--;
      currentPart += pair;
      index += 2;
      continue;
    }

    if (content[index] === "|" && templateDepth === 0 && linkDepth === 0) {
      argumentParts.push(currentPart);
      currentPart = "";
      index++;
      continue;
    }

    currentPart += content[index];
    index++;
  }

  argumentParts.push(currentPart);

  return argumentParts;
};

/**
 * MediaWiki treats the first "=" in an argument as the name/value separator,
 * but only when it sits outside any nested template or link.
 */
const findNameSeparatorIndex = (argumentPart: string) => {
  let templateDepth = 0;
  let linkDepth = 0;
  let index = 0;

  while (index < argumentPart.length) {
    const pair = argumentPart.slice(index, index + 2);

    if (pair === "{{") {
      templateDepth++;
      index += 2;
      continue;
    }

    if (pair === "}}") {
      templateDepth--;
      index += 2;
      continue;
    }

    if (pair === "[[") {
      linkDepth++;
      index += 2;
      continue;
    }

    if (pair === "]]") {
      linkDepth--;
      index += 2;
      continue;
    }

    if (argumentPart[index] === "=" && templateDepth === 0 && linkDepth === 0) {
      return index;
    }

    index++;
  }

  return -1;
};

/**
 * Finds every template in a page, at every nesting depth, by matching braces
 * rather than by regular expression. Etymology templates routinely contain
 * other templates, which a character-class regex cannot span.
 */
export default (wikitext: string): WikitextTemplate[] => {
  const templates: WikitextTemplate[] = [];
  const openBraceIndexes: number[] = [];
  let index = 0;

  while (index < wikitext.length) {
    const pair = wikitext.slice(index, index + 2);

    if (pair === "{{") {
      openBraceIndexes.push(index);
      index += 2;
      continue;
    }

    if (pair === "}}") {
      const startIndex = openBraceIndexes.pop();

      if (startIndex !== undefined) {
        const raw = wikitext.slice(startIndex, index + 2);
        const argumentParts = splitArgumentsAtTopLevel(raw.slice(2, -2));
        const positional: string[] = [];
        const named = new Map<string, string>();

        for (const argumentPart of argumentParts.slice(1)) {
          const separatorIndex = findNameSeparatorIndex(argumentPart);

          if (separatorIndex === -1) {
            positional.push(argumentPart.trim());
            continue;
          }

          named.set(
            argumentPart.slice(0, separatorIndex).trim().toLowerCase(),
            argumentPart.slice(separatorIndex + 1).trim(),
          );
        }

        templates.push({
          name: argumentParts[0].trim().toLowerCase(),
          positional,
          named,
          raw,
          startIndex,
        });
      }

      index += 2;
      continue;
    }

    index++;
  }

  return templates;
};
