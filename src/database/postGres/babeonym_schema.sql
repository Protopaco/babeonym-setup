CREATE TYPE "given_name_state" AS ENUM (
  'Selected',
  'Rejected',
  'Snoozed'
);

CREATE TYPE "genders" AS ENUM (
  'Male',
  'Female',
  'Neutral'
);

CREATE TABLE "users" (
  "id" serial PRIMARY KEY,
  "foreign_id" text UNIQUE NOT NULL,
  "email" text UNIQUE NOT NULL,
  "sur_name" text UNIQUE NOT NULL,
  "active" boolean DEFAULT true,
  "date_created" timestamp,
  "date_updated" timestamp
);

CREATE TABLE "user_settings" (
  "id" serial PRIMARY KEY,
  "user_id" int NOT NULL,
  "theme_id" int NOT NULL,
  "date_created" timestamp,
  "date_updated" timestamp
);

CREATE TABLE "themes" (
  "id" serial PRIMARY KEY,
  "name" text UNIQUE NOT NULL,
  "description" text,
  "date_created" timestamp
);

CREATE TABLE "given_names" (
  "id" serial PRIMARY KEY,
  "display_name" text UNIQUE NOT NULL,
  "date_created" timestamp
);

CREATE TABLE "user_given_names_states" (
  "id" serial PRIMARY KEY,
  "user_id" int NOT NULL,
  "given_name_id" int NOT NULL,
  "state" given_name_state NOT NULL,
  "date_created" timestamp,
  "date_updated" timestamp
);

CREATE TABLE "decades" (
  "id" serial PRIMARY KEY,
  "decade" int UNIQUE NOT NULL,
  "label" text NOT NULL
);

CREATE TABLE "given_name_ratings" (
  "id" serial PRIMARY KEY,
  "user_id" int NOT NULL,
  "given_name_id" int NOT NULL,
  "rating" numeric NOT NULL DEFAULT 1200,
  "date_created" timestamp NOT NULL,
  "date_updated" timestamp NOT NULL
);

CREATE TABLE "given_name_occurrences" (
  "id" serial PRIMARY KEY,
  "given_name_id" int NOT NULL,
  "year" int NOT NULL,
  "occurrences" int NOT NULL,
  "gender" genders NOT NULL,
  "date_created" timestamp
);

CREATE TABLE "given_name_popularity_by_decade" (
  "id" serial PRIMARY KEY,
  "given_name_id" int NOT NULL,
  "gender" genders NOT NULL,
  "decade_id" int NOT NULL,
  "rank" int NOT NULL, 
  "date_created" timestamp
);

CREATE TABLE "given_name_etymology" (
  "id" serial PRIMARY KEY,
  "given_name_id" int UNIQUE NOT NULL,
  "language_id" int,
  "culture_id" int,
  "meaning" text,
  "notes" text
);

CREATE TABLE "languages" (
  "id" serial PRIMARY KEY,
  "name" text UNIQUE NOT NULL
);

CREATE TABLE "cultures" (
  "id" serial PRIMARY KEY,
  "name" text UNIQUE NOT NULL
);

ALTER TABLE "user_settings" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id");

ALTER TABLE "user_settings" ADD FOREIGN KEY ("theme_id") REFERENCES "themes" ("id");

ALTER TABLE "user_given_names_states" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id");

ALTER TABLE "user_given_names_states" ADD FOREIGN KEY ("given_name_id") REFERENCES "given_names" ("id");

ALTER TABLE "given_name_ratings" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id");

ALTER TABLE "given_name_ratings" ADD FOREIGN KEY ("given_name_id") REFERENCES "given_names" ("id");

ALTER TABLE "given_name_occurrences" ADD FOREIGN KEY ("given_name_id") REFERENCES "given_names" ("id");

ALTER TABLE "given_name_popularity_by_decade" ADD FOREIGN KEY ("given_name_id") REFERENCES "given_names" ("id");

ALTER TABLE "given_name_popularity_by_decade" ADD FOREIGN KEY ("decade_id") REFERENCES "decades" ("id");

ALTER TABLE "given_name_etymology" ADD FOREIGN KEY ("given_name_id") REFERENCES "given_names" ("id");

ALTER TABLE "given_name_etymology" ADD FOREIGN KEY ("language_id") REFERENCES "languages" ("id");

ALTER TABLE "given_name_etymology" ADD FOREIGN KEY ("culture_id") REFERENCES "cultures" ("id");
