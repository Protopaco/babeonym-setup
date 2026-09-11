import normaliseMeaningText from "./normaliseMeaningText";
import parseFromField from "./parseFromField";
import parseSections from "./parseSections";
import parseTemplates from "./parseTemplates";
import type {
  ExtractedClaims,
  ExtractedRelationshipClaim,
  NameRelationshipType,
} from "../claimTypes";

const LANGUAGE_SECTION_CONFIDENCE = 0.9;
const FROM_ENDPOINT_CONFIDENCE = 0.8;
const FROM_TRANSMISSION_CONFIDENCE = 0.5;
/**
 * A gloss written inline on the source term — from=non:bjǫrn<t:bear> — is the
 * entry stating what the name means. It sits with the t= gloss on a derivation
 * template rather than with the looser mention glosses.
 */
const FROM_GLOSS_CONFIDENCE = 0.8;
const GENDER_CONFIDENCE = 0.8;
const RELATIONSHIP_CONFIDENCE = 0.75;
/**
 * eq= names the English equivalent of a foreign-language entry. It is looser
 * than a derivation claim — often it just repeats the page title, which the
 * insert discards as a self-reference — but it earns its place on the pairs
 * that cross languages, such as Esperanto Mateo to Matthew.
 */
const EQUIVALENT_CONFIDENCE = 0.6;

const RELATIONSHIP_FIELDS: Array<{
  field: string;
  relationshipType: NameRelationshipType;
  confidence: number;
}> = [
  {
    field: "varof",
    relationshipType: "variant",
    confidence: RELATIONSHIP_CONFIDENCE,
  },
  {
    field: "dimof",
    relationshipType: "diminutive",
    confidence: RELATIONSHIP_CONFIDENCE,
  },
  {
    field: "eq",
    relationshipType: "cognate",
    confidence: EQUIVALENT_CONFIDENCE,
  },
];

/**
 * Reads the {{given name}} template, which appears once per language section on
 * a page. Michael carries nine; Siobhan carries one.
 *
 * The section a template sits under is the strongest language signal available:
 * it is where Wiktionary itself files the entry, rather than a claim about
 * ancestry. from= is treated as a second, weaker signal.
 *
 * An origin written as a code and a term resolves through Wiktionary's own code
 * table, so from=de:Elisabeth becomes a German claim rather than a language
 * called "de:Elisabeth".
 */
export default (
  wikitext: string,
  canonicalNameByCode: Map<string, string>,
): ExtractedClaims => {
  const sections = parseSections(wikitext, 2);
  const givenNameTemplates = parseTemplates(wikitext).filter(
    (template) => template.name === "given name",
  );

  const claims: ExtractedClaims["claims"] = [];
  const relationships: ExtractedRelationshipClaim[] = [];
  const seenClaimKeys = new Set<string>();
  const seenRelationshipKeys = new Set<string>();

  const addClaim = (claim: ExtractedClaims["claims"][number]) => {
    // Language is in the key so a gloss given on two sources — the same words
    // for a Latin term and a Greek one — stays two meaning claims.
    const claimKey = [
      claim.claimType,
      claim.claimValue,
      claim.extractionMethod,
      claim.evidence.language ?? "",
    ].join("|");

    if (seenClaimKeys.has(claimKey)) {
      return;
    }

    seenClaimKeys.add(claimKey);
    claims.push(claim);
  };

  const addRelationship = (relationship: ExtractedRelationshipClaim) => {
    const relationshipKey = [
      relationship.relatedName,
      relationship.relationshipType,
      relationship.extractionMethod,
    ].join("|");

    if (seenRelationshipKeys.has(relationshipKey)) {
      return;
    }

    seenRelationshipKeys.add(relationshipKey);
    relationships.push(relationship);
  };

  for (const template of givenNameTemplates) {
    const section = sections.find(
      (candidate) =>
        template.startIndex >= candidate.contentStartIndex &&
        template.startIndex < candidate.endIndex,
    );

    if (section) {
      addClaim({
        claimType: "language_of_origin",
        claimValue: section.title,
        extractionMethod: "wiktionary_language_section",
        confidence: LANGUAGE_SECTION_CONFIDENCE,
        evidence: {
          section: section.title,
          template: template.raw,
        },
      });
    }

    const fromFieldValue = template.named.get("from");
    if (fromFieldValue) {
      for (const entry of parseFromField(fromFieldValue, canonicalNameByCode)) {
        const evidence = {
          section: section?.title ?? null,
          field: "from",
          rawField: fromFieldValue,
          code: entry.code,
          term: entry.term,
          // What a gloss on this source is resolved against, the same field
          // the etymology meanings carry.
          language: entry.language,
          template: template.raw,
        };

        addClaim({
          claimType: "language_of_origin",
          claimValue: entry.language,
          extractionMethod: entry.isTransmission
            ? "wiktionary_given_name_from_transmission"
            : "wiktionary_given_name_from",
          confidence: entry.isTransmission
            ? FROM_TRANSMISSION_CONFIDENCE
            : FROM_ENDPOINT_CONFIDENCE,
          evidence,
        });

        const gloss = entry.gloss ? normaliseMeaningText(entry.gloss) : "";

        if (gloss) {
          addClaim({
            claimType: "meaning",
            claimValue: gloss,
            extractionMethod: "wiktionary_given_name_from_gloss",
            confidence: FROM_GLOSS_CONFIDENCE,
            evidence,
          });
        }
      }
    }

    const gender = template.positional[1];
    if (gender) {
      addClaim({
        claimType: "gender",
        claimValue: gender,
        extractionMethod: "wiktionary_given_name_gender",
        confidence: GENDER_CONFIDENCE,
        evidence: {
          section: section?.title ?? null,
          languageCode: template.positional[0] ?? null,
          template: template.raw,
        },
      });
    }

    for (const {
      field,
      relationshipType,
      confidence,
    } of RELATIONSHIP_FIELDS) {
      const relatedName = template.named.get(field);

      if (!relatedName) {
        continue;
      }

      addRelationship({
        relatedName: relatedName
          .replace(/\[\[([^\]|]*)\|([^\]]*)\]\]/g, "$2")
          .replace(/\[\[([^\]]*)\]\]/g, "$1")
          .trim(),
        relationshipType,
        extractionMethod: `wiktionary_given_name_${field}`,
        confidence,
        evidence: {
          section: section?.title ?? null,
          field,
          template: template.raw,
        },
      });
    }
  }

  return { claims, relationships };
};
