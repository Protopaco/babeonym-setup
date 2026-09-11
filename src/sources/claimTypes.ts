/** Mirrors the data_claim_type enum in the workbench schema. */
export type NameClaimType =
  | "language_of_origin"
  | "culture_of_origin"
  | "meaning"
  | "gender";

/** Mirrors name_family_relationship_type, minus the values the pair model does not use. */
export type NameRelationshipType =
  | "variant"
  | "spelling_variant"
  | "diminutive"
  | "cognate"
  | "transliteration"
  | "cross_gender";

export type ExtractedNameClaim = {
  claimType: NameClaimType;
  /**
   * Stored exactly as the source wrote it. Resolution onto the languages table
   * happens later, against the curated alias tables.
   */
  claimValue: string;
  extractionMethod: string;
  confidence: number;
  evidence: Record<string, unknown>;
};

export type ExtractedRelationshipClaim = {
  relatedName: string;
  relationshipType: NameRelationshipType;
  extractionMethod: string;
  confidence: number;
  evidence: Record<string, unknown>;
};

export type ExtractedClaims = {
  claims: ExtractedNameClaim[];
  relationships: ExtractedRelationshipClaim[];
};
