import selectItems from "./selectItems";
import { SparqlBinding, toEntityId } from "./sparqlClient";
import type {
  ExtractedClaims,
  NameRelationshipType,
} from "../claimTypes";

/** What fetchWikidata stores in source_documents.raw_payload, one row per name. */
export type WikidataDocument = {
  identity: SparqlBinding[];
  relationships: SparqlBinding[];
};

export type WikidataExtraction = ExtractedClaims & {
  /** Language items encountered, for the QID-to-languages mapping table. */
  languageItems: Array<{ itemQid: string; label: string | null }>;
};

const GENDER_BY_TYPE_QID: Record<string, string> = {
  Q11879590: "female",
  Q12308941: "male",
  Q3409032: "unisex",
};

const RELATIONSHIP_BY_PROPERTY: Record<
  string,
  { relationshipType: NameRelationshipType; confidence: number }
> = {
  // said to be the same as — symmetric and loose. Michael's list reaches Mika.
  P460: { relationshipType: "cognate", confidence: 0.7 },
  // short name — directed, and the basis for inherited meaning.
  P1813: { relationshipType: "diminutive", confidence: 0.8 },
  // given name version for other gender — directed and unambiguous.
  P1560: { relationshipType: "cross_gender", confidence: 0.85 },
};

const LANGUAGE_CONFIDENCE = 0.85;
const GENDER_CONFIDENCE = 0.8;

/**
 * Wikidata carries languages and relationships as typed statements, and no
 * meaning at all — not on any item sampled. Meaning comes only from
 * Wiktionary's etymology.
 */
export default (document: WikidataDocument): WikidataExtraction => {
  const selectedItemQids = selectItems(document.identity);

  const claims: WikidataExtraction["claims"] = [];
  const relationships: WikidataExtraction["relationships"] = [];
  const languageItems = new Map<string, string | null>();
  const seenClaimKeys = new Set<string>();
  const seenRelationshipKeys = new Set<string>();

  for (const binding of document.identity) {
    if (!binding.item || !selectedItemQids.has(toEntityId(binding.item.value))) {
      continue;
    }

    const itemQid = toEntityId(binding.item.value);

    if (binding.language) {
      const languageQid = toEntityId(binding.language.value);
      const languageLabel = binding.languageLabel?.value ?? null;

      languageItems.set(languageQid, languageLabel);

      const claimKey = `language|${languageQid}`;
      if (!seenClaimKeys.has(claimKey)) {
        seenClaimKeys.add(claimKey);
        claims.push({
          claimType: "language_of_origin",
          claimValue: languageQid,
          extractionMethod: "wikidata_language_of_work_or_name",
          confidence: LANGUAGE_CONFIDENCE,
          evidence: {
            item: itemQid,
            languageLabel,
          },
        });
      }
    }

    const gender = binding.type
      ? GENDER_BY_TYPE_QID[toEntityId(binding.type.value)]
      : undefined;

    if (gender) {
      const claimKey = `gender|${gender}`;
      if (!seenClaimKeys.has(claimKey)) {
        seenClaimKeys.add(claimKey);
        claims.push({
          claimType: "gender",
          claimValue: gender,
          extractionMethod: "wikidata_item_type_gender",
          confidence: GENDER_CONFIDENCE,
          evidence: {
            item: itemQid,
            type: toEntityId(binding.type!.value),
          },
        });
      }
    }
  }

  for (const binding of document.relationships) {
    if (!binding.item || !selectedItemQids.has(toEntityId(binding.item.value))) {
      continue;
    }

    if (!binding.property || !binding.relatedLabel) {
      continue;
    }

    const relationship =
      RELATIONSHIP_BY_PROPERTY[toEntityId(binding.property.value)];

    if (!relationship) {
      continue;
    }

    const relatedName = binding.relatedLabel.value.trim();
    const relationshipKey = `${relatedName}|${relationship.relationshipType}`;

    if (seenRelationshipKeys.has(relationshipKey)) {
      continue;
    }

    seenRelationshipKeys.add(relationshipKey);
    relationships.push({
      relatedName,
      relationshipType: relationship.relationshipType,
      extractionMethod: `wikidata_${toEntityId(binding.property.value).toLowerCase()}`,
      confidence: relationship.confidence,
      evidence: {
        item: toEntityId(binding.item.value),
        property: toEntityId(binding.property.value),
        related: binding.related ? toEntityId(binding.related.value) : null,
      },
    });
  }

  return {
    claims,
    relationships,
    languageItems: [...languageItems.entries()].map(([itemQid, label]) => ({
      itemQid,
      label,
    })),
  };
};
