import { SparqlBinding, toEntityId } from "./sparqlClient";

/** Latin script (Q8229). */
const LATIN_SCRIPT_QID = "Q8229";

/**
 * A label can match several given-name items. Michael matches four — one Latin,
 * plus separate items for Μιχαήλ, מיכאל and Միքայել — and Mika matches around
 * thirty, mostly Japanese kanji spellings.
 *
 * Filtering to Latin script removes the ones that are really a different
 * written name. It does not always leave exactly one: of fifty names sampled,
 * Mika kept three and Lakshmi and Julian two each. Every survivor is kept
 * rather than picking a winner, because nothing in the source says which is
 * canonical, and inventing that judgment is the thing the pair model was
 * chosen to avoid. Language claims from several items simply union.
 */
export default (bindingsForName: SparqlBinding[]) => {
  const scriptsByItem = new Map<string, Set<string>>();

  for (const binding of bindingsForName) {
    if (!binding.item) {
      continue;
    }

    const itemQid = toEntityId(binding.item.value);

    if (!scriptsByItem.has(itemQid)) {
      scriptsByItem.set(itemQid, new Set());
    }

    if (binding.script) {
      scriptsByItem.get(itemQid)!.add(toEntityId(binding.script.value));
    }
  }

  const latinScriptItems = [...scriptsByItem.entries()]
    .filter(([, scripts]) => scripts.has(LATIN_SCRIPT_QID))
    .map(([itemQid]) => itemQid);

  return new Set(
    latinScriptItems.length > 0 ? latinScriptItems : [...scriptsByItem.keys()],
  );
};
