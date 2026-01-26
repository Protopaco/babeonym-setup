CREATE TYPE "given_name_state" AS ENUM (
  'selected',
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
  'boy',
  'girl'
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

CREATE TABLE "user_given_names_states" (
  "id" SERIAL PRIMARY KEY,
  "user_id" INT REFERENCES "users" ("id") NOT NULL,
  "given_custom_name_bridge_id" INT NOT NULL REFERENCES "given_custom_name_bridge" ("id"),
  "state" given_name_state NOT NULL,
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
  "date_updated" TIMESTAMP NOT NULL DEFAULT NOW(),

  UNIQUE (user_id, given_custom_name_bridge_id)
);

CREATE TABLE "given_custom_name_bridge" (
  "id" SERIAL PRIMARY KEY,
  "given_name_id" INT REFERENCES "given_names" ("id") NULL,
  "custom_given_name_id" INT REFERENCES "custom_given_names" ("id") NULL,
  CHECK (
    (given_name_id IS NOT NULL AND custom_given_name_id IS NULL)
    OR
    (given_name_id IS NULL AND custom_given_name_id IS NOT NULL)
  )
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
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE "given_name_popularity_by_decade" (
  "id" SERIAL PRIMARY KEY,
  "given_name_id" INT REFERENCES "given_names" ("id") NOT NULL,
  "gender" gender NOT NULL,
  "decade_id" INT REFERENCES "decades" ("id") NOT NULL,
  "rank" INT NOT NULL, 
  "percentile" NUMERIC NOT NULL CHECK (percentile >= 0 AND percentile <= 1),
  "date_created" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE "languages" (
  "id" SERIAL PRIMARY KEY,
  "name" TEXT UNIQUE NOT NULL
);

CREATE TABLE "cultures" (
  "id" SERIAL PRIMARY KEY,
  "name" TEXT UNIQUE NOT NULL
);

CREATE TABLE "given_name_etymology" (
  "id" SERIAL PRIMARY KEY,
  "given_name_id" INT REFERENCES "given_names" ("id") NOT NULL,
  "language_id" INT REFERENCES "languages" ("id"),
  "culture_id" INT REFERENCES "cultures" ("id"),
  "meaning" TEXT,
  "notes" TEXT
);


CREATE UNIQUE INDEX uniq_given_name_bridge
ON given_custom_name_bridge (given_name_id)
WHERE given_name_id IS NOT NULL;

CREATE UNIQUE INDEX uniq_custom_name_bridge
ON given_custom_name_bridge (custom_given_name_id)
WHERE custom_given_name_id IS NOT NULL;
