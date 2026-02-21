CREATE TYPE "given_name_state" AS ENUM (
  'approved',
  'rejected',
  'snoozed'
);

CREATE TYPE "gender" AS ENUM (
  'male',
  'female',
  'neutral'
);

CREATE TYPE "auth_provider" AS ENUM (
  'google',
  'microsoft',
  'anonymous'
);

CREATE TYPE "theme" AS ENUM (
  'light',
  'dark',
  'blue',
  'pink'
);

CREATE TABLE "users" (
  "id" SERIAL PRIMARY KEY,
  "foreign_id" TEXT,
  "auth_provider" auth_provider NOT NULL,
  "email" TEXT UNIQUE,
  "user_name" TEXT,
  "last_active" TIMESTAMP NOT NULL DEFAULT NOW(),
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE (foreign_id, auth_provider)
);

CREATE TABLE "user_settings" (
  "id" SERIAL PRIMARY KEY,
  "user_id" integer REFERENCES "users" ("id") UNIQUE NOT NULL,
  "theme" theme NOT NULL DEFAULT 'light',
  "sur_name" TEXT,
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
  "date_updated" TIMESTAMP NOT NULL DEFAULT NOW()
);


CREATE TABLE "given_names" (
  "id" SERIAL PRIMARY KEY,
  "given_name" TEXT UNIQUE NOT NULL,
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE "custom_given_names" (
  "id" SERIAL PRIMARY KEY,
  "user_id" INT REFERENCES "users" ("id") NOT NULL,
  "given_name" TEXT NOT NULL,
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, given_name)
);

CREATE TABLE "given_custom_name_bridge" (
  "id" SERIAL PRIMARY KEY,
  "given_name_id" INT REFERENCES "given_names" ("id") NULL UNIQUE,
  "custom_given_name_id" INT REFERENCES "custom_given_names" ("id") NULL UNIQUE,
  CHECK (
    (given_name_id IS NOT NULL AND custom_given_name_id IS NULL)
    OR
    (given_name_id IS NULL AND custom_given_name_id IS NOT NULL)
  )
);

CREATE TABLE "user_given_names_states" (
  "id" SERIAL PRIMARY KEY,
  "user_id" INT REFERENCES "users" ("id") NOT NULL,
  "given_custom_name_bridge_id" INT NOT NULL REFERENCES "given_custom_name_bridge" ("id"),
  "state" given_name_state NOT NULL,
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
  "date_updated" TIMESTAMP NOT NULL DEFAULT NOW(),

  UNIQUE (user_id, given_custom_name_bridge_id)
);

CREATE TABLE "decades" (
  "id" SERIAL PRIMARY KEY,
  "decade" INT UNIQUE NOT NULL,
  "label" TEXT NOT NULL
);

CREATE TABLE "given_name_ratings" (
  "id" SERIAL PRIMARY KEY,
  "user_id" INT REFERENCES "users" ("id") NOT NULL,
  "given_custom_name_bridge_id" INT NOT NULL REFERENCES "given_custom_name_bridge" ("id"),
  "rating" NUMERIC NOT NULL DEFAULT 1200,
  "vote_for" INT NOT NULL DEFAULT 0,
  "vote_total" INT NOT NULL DEFAULT 0,
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
  "date_updated" TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, given_custom_name_bridge_id)
);

CREATE TABLE "given_name_occurrences" (
  "id" SERIAL PRIMARY KEY,
  "given_name_id" INT REFERENCES "given_names" ("id") NOT NULL,
  "year" INT NOT NULL,
  "occurrences" INT NOT NULL,
  "gender" gender NOT NULL,
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE (given_name_id, year, gender)
);

CREATE TABLE "given_name_popularity_by_decade" (
  "id" SERIAL PRIMARY KEY,
  "given_name_id" INT REFERENCES "given_names" ("id") NOT NULL,
  "gender" gender NOT NULL,
  "decade_id" INT REFERENCES "decades" ("id") NOT NULL,
  "rank" INT NOT NULL, 
  "percentile" NUMERIC NOT NULL CHECK (percentile >= 0 AND percentile <= 1),
  "total_occurrences" BIGINT,
  "female_share" NUMERIC,
  "gender_difference" NUMERIC,
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE "languages" (
  "id" SERIAL PRIMARY KEY,
  "label" TEXT UNIQUE NOT NULL,
  "flag" TEXT NOT NULL
);

CREATE TABLE "cultures" (
  "id" SERIAL PRIMARY KEY,
  "label" TEXT UNIQUE NOT NULL
);

CREATE TABLE "regions" (
  "id" INT PRIMARY KEY,
  "label" TEXT NOT NULL UNIQUE,
  "parent_id" INT NULL REFERENCES regions(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS culture_region_bridge (
  culture_id INT NOT NULL REFERENCES cultures(id) ON DELETE CASCADE,
  region_id INT NOT NULL REFERENCES regions(id) ON DELETE CASCADE,
  date_created TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (culture_id, region_id)
);

CREATE INDEX IF NOT EXISTS idx_regions_parent_id
  ON regions(parent_id);

CREATE INDEX IF NOT EXISTS idx_culture_region_bridge_region
  ON culture_region_bridge(region_id);

CREATE INDEX IF NOT EXISTS idx_culture_region_bridge_culture
  ON culture_region_bridge(culture_id);

  CREATE TABLE "language_region_bridge" (
  "language_id" INT NOT NULL REFERENCES languages(id) ON DELETE CASCADE,
  "region_id" INT NOT NULL REFERENCES regions(id) ON DELETE CASCADE,
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (language_id, region_id)
);

CREATE INDEX IF NOT EXISTS idx_language_region_bridge_region
  ON language_region_bridge(region_id);

CREATE INDEX IF NOT EXISTS idx_language_region_bridge_language
  ON language_region_bridge(language_id);


CREATE TABLE given_name_meaning (
  given_name_id INT PRIMARY KEY REFERENCES given_names(id),
  meaning_short TEXT,
  meaning_long  TEXT,
  date_created  TIMESTAMP NOT NULL DEFAULT NOW(),
  date_updated  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE given_name_culture_bridge (
  given_name_id INT NOT NULL REFERENCES given_names(id),
  culture_id    INT NOT NULL REFERENCES cultures(id),
  date_created  TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (given_name_id, culture_id)
);

CREATE TABLE given_name_language_bridge (
  given_name_id INT NOT NULL REFERENCES given_names(id),
  language_id   INT NOT NULL REFERENCES languages(id),
  date_created  TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (given_name_id, language_id)
);

-- Create user_sessions table for session storage
CREATE TABLE user_sessions (
    sid VARCHAR NOT NULL COLLATE "default" PRIMARY KEY,
    sess JSON NOT NULL,
    expire TIMESTAMP(6) NOT NULL
) WITH (OIDS=FALSE);

-- Create index for better performance
CREATE INDEX idx_user_sessions_expire ON user_sessions(expire);

CREATE UNIQUE INDEX uniq_given_name_bridge
ON given_custom_name_bridge (given_name_id)
WHERE given_name_id IS NOT NULL;

CREATE UNIQUE INDEX uniq_custom_name_bridge
ON given_custom_name_bridge (custom_given_name_id)
WHERE custom_given_name_id IS NOT NULL;
