export type FromFieldEntry = {
  /** The token exactly as written, e.g. "Ancient Greek", "surnames", "la:Iulianus". */
  language: string;
  /**
   * True for a language the name merely passed through. "Latin < Ancient Greek
   * < Hebrew" reads as "from Latin, which took it from Ancient Greek, which
   * took it from Hebrew" — Latin is the proximate source, Hebrew the ultimate
   * origin, and Ancient Greek is transit.
   */
  isTransmission: boolean;
};

/**
 * Wiktionary's from= field uses two separators with different meanings:
 * "," lists independent sources ("English,Spanish"), while "<" walks a
 * derivation chain. About one in five values in a sample of fifty pages was a
 * chain, so neither can be ignored.
 */
export default (fromFieldValue: string): FromFieldEntry[] => {
  const entries: FromFieldEntry[] = [];

  for (const listItem of fromFieldValue.split(",")) {
    const chain = listItem
      .split("<")
      .map((token) => token.trim())
      .filter((token) => token.length > 0);

    chain.forEach((language, chainIndex) => {
      entries.push({
        language,
        isTransmission: chainIndex > 0 && chainIndex < chain.length - 1,
      });
    });
  }

  return entries;
};
