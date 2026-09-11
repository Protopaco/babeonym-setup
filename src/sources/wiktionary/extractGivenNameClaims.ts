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
 */
export default (wikitext: string): ExtractedClaims => {
  const sections = parseSections(wikitext, 2);
  const givenNameTemplates = parseTemplates(wikitext).filter(
    (template) => template.name === "given name",
  );

  const claims: ExtractedClaims["claims"] = [];
  const relationships: ExtractedRelationshipClaim[] = [];
  const seenClaimKeys = new Set<string>();
  const seenRelationshipKeys = new Set<string>();

  const addClaim = (claim: ExtractedClaims["claims"][number]) => {
    const claimKey = [
      claim.claimType,
      claim.claimValue,
      claim.extractionMethod,
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
      for (const entry of parseFromField(fromFieldValue)) {
        addClaim({
          claimType: "language_of_origin",
          claimValue: entry.language,
          extractionMethod: entry.isTransmission
            ? "wiktionary_given_name_from_transmission"
            : "wiktionary_given_name_from",
          confidence: entry.isTransmission
            ? FROM_TRANSMISSION_CONFIDENCE
            : FROM_ENDPOINT_CONFIDENCE,
          evidence: {
            section: section?.title ?? null,
            field: "from",
            rawField: fromFieldValue,
            template: template.raw,
          },
        });
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
