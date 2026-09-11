import extractGivenNameClaims from "./extractGivenNameClaims";
import extractMeaningClaims from "./extractMeaningClaims";
import type { ExtractedClaims } from "../claimTypes";

/**
 * Everything a stored Wiktionary page yields: language and gender claims plus
 * relationships from {{given name}}, and meaning claims from the etymology.
 *
 * Nothing here touches the network. Rules can be rewritten and re-run against
 * source_documents as often as needed. The language-code table is passed in
 * for the same reason, rather than loaded here.
 */
export default (
  rawText: string,
  canonicalNameByCode: Map<string, string>,
): ExtractedClaims => {
  const givenNameClaims = extractGivenNameClaims(rawText, canonicalNameByCode);
  const meaningClaims = extractMeaningClaims(rawText, canonicalNameByCode);

  return {
    claims: [...givenNameClaims.claims, ...meaningClaims],
    relationships: givenNameClaims.relationships,
  };
};
