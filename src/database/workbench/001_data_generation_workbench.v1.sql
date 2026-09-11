DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'data_source_type') THEN
    CREATE TYPE "data_source_type" AS ENUM (
      'wiktionary',
      'wikidata',
      'manual',
      'other'
    );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'data_claim_type') THEN
    CREATE TYPE "data_claim_type" AS ENUM (
      'language_of_origin',
      'culture_of_origin',
      'meaning',
      'name_family'
    );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'data_claim_status') THEN
    CREATE TYPE "data_claim_status" AS ENUM (
      'raw',
      'candidate',
      'approved',
      'rejected'
    );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'name_family_relationship_type') THEN
    CREATE TYPE "name_family_relationship_type" AS ENUM (
      'canonical',
      'variant',
      'spelling_variant',
      'diminutive',
      'cognate',
      'transliteration',
      'unrelated_homograph'
    );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'pipeline_run_status') THEN
    CREATE TYPE "pipeline_run_status" AS ENUM (
      'running',
      'completed',
      'failed'
    );
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS "data_sources" (
  "id" SERIAL PRIMARY KEY,
  "source_type" data_source_type NOT NULL,
  "label" TEXT UNIQUE NOT NULL,
  "base_url" TEXT,
  "license_note" TEXT,
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "source_documents" (
  "id" SERIAL PRIMARY KEY,
  "data_source_id" INT NOT NULL REFERENCES "data_sources" ("id"),
  "source_key" TEXT NOT NULL,
  "url" TEXT,
  "raw_payload" JSONB,
  "raw_text" TEXT,
  "fetched_at" TIMESTAMP NOT NULL DEFAULT NOW(),
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
  "date_updated" TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE ("data_source_id", "source_key")
);

CREATE TABLE IF NOT EXISTS "name_families" (
  "id" SERIAL PRIMARY KEY,
  "canonical_name" TEXT UNIQUE NOT NULL,
  "status" data_claim_status NOT NULL DEFAULT 'candidate',
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
  "date_updated" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "given_name_family_bridge" (
  "id" SERIAL PRIMARY KEY,
  "given_name_id" INT NOT NULL REFERENCES "given_names" ("id"),
  "name_family_id" INT NOT NULL REFERENCES "name_families" ("id"),
  "relationship_type" name_family_relationship_type NOT NULL,
  "confidence" NUMERIC NOT NULL DEFAULT 0.5 CHECK (confidence >= 0 AND confidence <= 1),
  "status" data_claim_status NOT NULL DEFAULT 'candidate',
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
  "date_updated" TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE ("given_name_id", "name_family_id", "relationship_type")
);

CREATE TABLE IF NOT EXISTS "name_claims" (
  "id" SERIAL PRIMARY KEY,
  "given_name_id" INT REFERENCES "given_names" ("id"),
  "name_family_id" INT REFERENCES "name_families" ("id"),
  "claim_type" data_claim_type NOT NULL,
  "claim_value" TEXT NOT NULL,
  "source_document_id" INT REFERENCES "source_documents" ("id"),
  "extraction_method" TEXT NOT NULL,
  "confidence" NUMERIC NOT NULL DEFAULT 0.5 CHECK (confidence >= 0 AND confidence <= 1),
  "status" data_claim_status NOT NULL DEFAULT 'candidate',
  "evidence" JSONB,
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
  "date_updated" TIMESTAMP NOT NULL DEFAULT NOW(),
  CHECK (
    (given_name_id IS NOT NULL AND name_family_id IS NULL)
    OR
    (given_name_id IS NULL AND name_family_id IS NOT NULL)
  )
);

CREATE TABLE IF NOT EXISTS "given_name_family_candidates" (
  "id" SERIAL PRIMARY KEY,
  "given_name_id" INT NOT NULL REFERENCES "given_names" ("id"),
  "candidate_given_name_id" INT NOT NULL REFERENCES "given_names" ("id"),
  "suggested_relationship_type" name_family_relationship_type NOT NULL,
  "score" NUMERIC NOT NULL CHECK (score >= 0 AND score <= 1),
  "method" TEXT NOT NULL,
  "status" data_claim_status NOT NULL DEFAULT 'candidate',
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
  "date_updated" TIMESTAMP NOT NULL DEFAULT NOW(),
  CHECK (given_name_id <> candidate_given_name_id),
  UNIQUE ("given_name_id", "candidate_given_name_id", "method")
);

CREATE TABLE IF NOT EXISTS "pipeline_runs" (
  "id" SERIAL PRIMARY KEY,
  "label" TEXT,
  "status" pipeline_run_status NOT NULL DEFAULT 'running',
  "started_at" TIMESTAMP NOT NULL DEFAULT NOW(),
  "finished_at" TIMESTAMP,
  "metadata" JSONB
);

CREATE TABLE IF NOT EXISTS "pipeline_stage_runs" (
  "id" SERIAL PRIMARY KEY,
  "pipeline_run_id" INT NOT NULL REFERENCES "pipeline_runs" ("id") ON DELETE CASCADE,
  "stage_name" TEXT NOT NULL,
  "status" pipeline_run_status NOT NULL DEFAULT 'running',
  "records_processed" INT NOT NULL DEFAULT 0,
  "records_created" INT NOT NULL DEFAULT 0,
  "records_updated" INT NOT NULL DEFAULT 0,
  "error_message" TEXT,
  "started_at" TIMESTAMP NOT NULL DEFAULT NOW(),
  "finished_at" TIMESTAMP,
  "metadata" JSONB
);

CREATE INDEX IF NOT EXISTS idx_source_documents_data_source_id
  ON source_documents(data_source_id);

CREATE INDEX IF NOT EXISTS idx_name_families_status
  ON name_families(status);

CREATE INDEX IF NOT EXISTS idx_given_name_family_bridge_given_name_id
  ON given_name_family_bridge(given_name_id);

CREATE INDEX IF NOT EXISTS idx_given_name_family_bridge_name_family_id
  ON given_name_family_bridge(name_family_id);

CREATE INDEX IF NOT EXISTS idx_given_name_family_bridge_status
  ON given_name_family_bridge(status);

CREATE INDEX IF NOT EXISTS idx_name_claims_given_name_id
  ON name_claims(given_name_id);

CREATE INDEX IF NOT EXISTS idx_name_claims_name_family_id
  ON name_claims(name_family_id);

CREATE INDEX IF NOT EXISTS idx_name_claims_claim_type
  ON name_claims(claim_type);

CREATE INDEX IF NOT EXISTS idx_name_claims_status
  ON name_claims(status);

CREATE INDEX IF NOT EXISTS idx_given_name_family_candidates_given_name_id
  ON given_name_family_candidates(given_name_id);

CREATE INDEX IF NOT EXISTS idx_given_name_family_candidates_candidate_given_name_id
  ON given_name_family_candidates(candidate_given_name_id);

CREATE INDEX IF NOT EXISTS idx_given_name_family_candidates_status
  ON given_name_family_candidates(status);

CREATE INDEX IF NOT EXISTS idx_pipeline_stage_runs_pipeline_run_id
  ON pipeline_stage_runs(pipeline_run_id);

CREATE INDEX IF NOT EXISTS idx_pipeline_stage_runs_stage_name
  ON pipeline_stage_runs(stage_name);
