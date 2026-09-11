import extractGivenNameClaims from "./extractGivenNameClaims";
import extractMeaningClaims from "./extractMeaningClaims";
import type { ExtractedClaims } from "../claimTypes";

/**
 * Everything a stored Wiktionary page yields: language and gender claims plus
 * relationships from {{given name}}, and meaning claims from the etymology.
 *
 * Nothing here touches the network. Rules can be rewritten and re-run against
 * source_documents as often as needed.
 */
export default (rawText: string): ExtractedClaims => {
  const givenNameClaims = extractGivenNameClaims(rawText);
  const meaningClaims = extractMeaningClaims(rawText);

  return {
    claims: [...givenNameClaims.claims, ...meaningClaims],
    relationships: givenNameClaims.relationships,
  };
};
