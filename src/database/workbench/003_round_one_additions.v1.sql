DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'alias_review_status') THEN
    CREATE TYPE "alias_review_status" AS ENUM (
      'unreviewed',
      'mapped',
      'rejected'
    );
  END IF;
END $$;

ALTER TYPE "data_claim_type" ADD VALUE IF NOT EXISTS 'gender';

ALTER TYPE "name_family_relationship_type" ADD VALUE IF NOT EXISTS 'cross_gender';

CREATE TABLE IF NOT EXISTS "wiktionary_language_aliases" (
  "alias" TEXT PRIMARY KEY,
  "language_id" INT REFERENCES "languages" ("id"),
  "status" alias_review_status NOT NULL DEFAULT 'unreviewed',
  "times_seen" INT NOT NULL DEFAULT 0,
  "first_seen_at" TIMESTAMP NOT NULL DEFAULT NOW(),
  "date_updated" TIMESTAMP NOT NULL DEFAULT NOW(),
  CHECK (status <> 'mapped' OR language_id IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS "wikidata_language_items" (
  "item_qid" TEXT PRIMARY KEY,
  "item_label" TEXT,
  "language_id" INT REFERENCES "languages" ("id"),
  "status" alias_review_status NOT NULL DEFAULT 'unreviewed',
  "times_seen" INT NOT NULL DEFAULT 0,
  "first_seen_at" TIMESTAMP NOT NULL DEFAULT NOW(),
  "date_updated" TIMESTAMP NOT NULL DEFAULT NOW(),
  CHECK (status <> 'mapped' OR language_id IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS "wikidata_given_name_types" (
  "item_qid" TEXT PRIMARY KEY,
  "label" TEXT,
  "date_updated" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "name_relationship_claims" (
  "id" SERIAL PRIMARY KEY,
  "given_name_id" INT NOT NULL REFERENCES "given_names" ("id"),
  "related_given_name_id" INT NOT NULL REFERENCES "given_names" ("id"),
  "relationship_type" name_family_relationship_type NOT NULL,
  "source_document_id" INT REFERENCES "source_documents" ("id"),
  "extraction_method" TEXT NOT NULL,
  "confidence" NUMERIC NOT NULL DEFAULT 0.5 CHECK (confidence >= 0 AND confidence <= 1),
  "status" data_claim_status NOT NULL DEFAULT 'candidate',
  "evidence" JSONB,
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
  "date_updated" TIMESTAMP NOT NULL DEFAULT NOW(),
  CHECK (given_name_id <> related_given_name_id),
  UNIQUE (
    "given_name_id",
    "related_given_name_id",
    "relationship_type",
    "extraction_method"
  )
);

CREATE INDEX IF NOT EXISTS idx_wiktionary_language_aliases_status
  ON wiktionary_language_aliases(status);

CREATE INDEX IF NOT EXISTS idx_wikidata_language_items_status
  ON wikidata_language_items(status);

CREATE INDEX IF NOT EXISTS idx_name_relationship_claims_given_name_id
  ON name_relationship_claims(given_name_id);

CREATE INDEX IF NOT EXISTS idx_name_relationship_claims_related_given_name_id
  ON name_relationship_claims(related_given_name_id);

CREATE INDEX IF NOT EXISTS idx_name_relationship_claims_relationship_type
  ON name_relationship_claims(relationship_type);

CREATE INDEX IF NOT EXISTS idx_name_relationship_claims_status
  ON name_relationship_claims(status);
