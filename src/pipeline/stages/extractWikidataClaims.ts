import { closePool, query } from "../../utils/postGresPool";
import extractWikidataClaims from "../../sources/wikidata/extractClaims";
import getPositiveIntArg from "../utils/getPositiveIntArg";
import refreshWikidataLanguageItems from "../utils/refreshWikidataLanguageItems";
import type { WikidataDocument } from "../../sources/wikidata/extractClaims";
import type {
  ExtractedNameClaim,
  ExtractedRelationshipClaim,
} from "../../sources/claimTypes";

type SourceDocumentRow = {
  source_document_id: number;
  given_name_id: number;
  source_key: string;
  raw_payload: WikidataDocument;
};

const getDocumentsToExtract = async (limit: number) => {
  const result = await query(
    `
      SELECT
        sd.id AS source_document_id,
        gn.id AS given_name_id,
        sd.source_key,
        sd.raw_payload
      FROM source_documents sd
      JOIN data_sources ds
        ON ds.id = sd.data_source_id
      JOIN given_names gn
        ON gn.given_name = sd.source_key
      WHERE ds.label = 'Wikidata'
        AND sd.raw_payload IS NOT NULL
      ORDER BY sd.id
      LIMIT $1
    `,
    [limit],
  );

  return result.rows as SourceDocumentRow[];
};

const clearPreviousCandidateClaims = async (sourceDocumentId: number) => {
  await query(
    `
      DELETE FROM name_claims
      WHERE source_document_id = $1
        AND status = 'candidate'
        AND extraction_method LIKE 'wikidata%'
    `,
    [sourceDocumentId],
  );

  await query(
    `
      DELETE FROM name_relationship_claims
      WHERE source_document_id = $1
        AND status = 'candidate'
        AND extraction_method LIKE 'wikidata%'
    `,
    [sourceDocumentId],
  );
};

const saveClaim = async (
  document: SourceDocumentRow,
  claim: ExtractedNameClaim,
) => {
  const result = await query(
    `
      INSERT INTO name_claims (
        given_name_id,
        claim_type,
        claim_value,
        source_document_id,
        extraction_method,
        confidence,
        status,
        evidence,
        date_updated
      )
      SELECT $1, $2, $3, $4, $5, $6, 'candidate', $7::jsonb, NOW()
      WHERE NOT EXISTS (
        SELECT 1
        FROM name_claims
        WHERE given_name_id = $1
          AND claim_type = $2
          AND claim_value = $3
          AND source_document_id = $4
          AND extraction_method = $5
      )
    `,
    [
      document.given_name_id,
      claim.claimType,
      claim.claimValue,
      document.source_document_id,
      claim.extractionMethod,
      claim.confidence,
      JSON.stringify(claim.evidence),
    ],
  );

  return result.rowCount ?? 0;
};

const saveRelationshipClaim = async (
  document: SourceDocumentRow,
  relationship: ExtractedRelationshipClaim,
) => {
  const result = await query(
    `
      INSERT INTO name_relationship_claims (
        given_name_id,
        related_given_name_id,
        relationship_type,
        source_document_id,
        extraction_method,
        confidence,
        status,
        evidence,
        date_updated
      )
      SELECT $1, related.id, $2, $3, $4, $5, 'candidate', $6::jsonb, NOW()
      FROM given_names related
      WHERE related.given_name = $7
        AND related.id <> $1
      ON CONFLICT (
        given_name_id,
        related_given_name_id,
        relationship_type,
        extraction_method
      ) DO NOTHING
    `,
    [
      document.given_name_id,
      relationship.relationshipType,
      document.source_document_id,
      relationship.extractionMethod,
      relationship.confidence,
      JSON.stringify(relationship.evidence),
      relationship.relatedName,
    ],
  );

  return result.rowCount ?? 0;
};

export default async () => {
  const limit = getPositiveIntArg("--limit", 50, 200000);
  const documents = await getDocumentsToExtract(limit);

  console.log(
    `Extracting Wikidata claims from ${documents.length} documents...`,
  );

  let claimCount = 0;
  let relationshipCount = 0;
  let keptRelationshipCount = 0;
  let documentsWithItems = 0;
  const languageItems = new Map<string, string | null>();

  try {
    for (const document of documents) {
      const extraction = extractWikidataClaims(document.raw_payload);

      await clearPreviousCandidateClaims(document.source_document_id);

      for (const claim of extraction.claims) {
        claimCount += await saveClaim(document, claim);
      }

      for (const relationship of extraction.relationships) {
        relationshipCount++;
        keptRelationshipCount += await saveRelationshipClaim(
          document,
          relationship,
        );
      }

      for (const languageItem of extraction.languageItems) {
        languageItems.set(languageItem.itemQid, languageItem.label);
      }

      if (extraction.claims.length > 0) {
        documentsWithItems++;
      }
    }

    const languageSummary = await refreshWikidataLanguageItems(
      [...languageItems.entries()].map(([itemQid, label]) => ({
        itemQid,
        label,
      })),
    );

    console.log(
      `Wikidata claim extraction complete. ${claimCount} claims, ${keptRelationshipCount} relationships kept of ${relationshipCount} offered.`,
    );
    console.log(
      `  ${documentsWithItems}/${documents.length} documents produced claims.`,
    );
    console.log(
      `  ${languageSummary.autoMappedCount} language items auto-mapped, ${languageSummary.unreviewedCount} awaiting review.`,
    );
  } finally {
    await closePool();
  }
};
