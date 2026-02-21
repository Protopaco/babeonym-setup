DROP TABLE IF EXISTS wikipedia_page_raw CASCADE;
DROP TABLE IF EXISTS wikipedia_page_ids CASCADE;

CREATE TABLE wikipedia_page_ids(
    "id" SERIAL PRIMARY KEY,
    "source" TEXT NOT NULL,
    "pageid" INT UNIQUE NOT NULL,
    "title" TEXT NOT NULL,
    "ns" INT NULL,
    "hits" INT NOT NULL DEFAULT 0,
    "resolved_pageid" INT NULL,
    "resolved_title" TEXT NULL,
    "is_redirect" BOOLEAN NOT NULL DEFAULT FALSE,
    "has_been_matched" BOOLEAN NOT NULL DEFAULT FALSE,
    "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
    "date_updated" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE wikipedia_page_raw(
    "id" SERIAL PRIMARY KEY,
    "pageid" INT UNIQUE REFERENCES wikipedia_page_ids(pageid) ON DELETE CASCADE,
    "infobox_json" JSONB,
    "sections_json" JSONB,
    "categories" TEXT[] DEFAULT '{}',
    "text" TEXT,
    "wtf_json" JSONB,
    "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
    "date_updated" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE wikipedia_parsing_table(
    "id" SERIAL PRIMARY KEY,
    "pageid" INT UNIQUE REFERENCES wikipedia_page_ids(pageid),
    "given_names" TEXT,
    "cultures" TEXT,
    "languages" TEXT,
    "meanings" TEXT,
    "date_created" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE page_language_bridge(
    "id" SERIAL PRIMARY KEY,
    "pageid" INT REFERENCES wikipedia_page_ids(pageid),
    "language_id" INT,
    "date_created" TIMESTAMP NOT NULL DEFAULT NOW() 
);
CREATE UNIQUE INDEX uniq_page_language_bridge ON page_language_bridge (pageid, language_id)

CREATE TABLE page_culture_bridge(
    "id" SERIAL PRIMARY KEY,
    "pageid" INT REFERENCES wikipedia_page_ids(pageid),
    "culture_id" INT,
    "date_created" TIMESTAMP NOT NULL DEFAULT NOW() 
);
CREATE UNIQUE INDEX uniq_page_culture_bridge ON page_culture_bridge (pageid, culture_id)


CREATE TABLE temp_culture_pages(
    "id" SERIAL PRIMARY KEY,
    "pageid" INT NOT NULL UNIQUE,
    "is_culture" BOOLEAN NOT NULL DEFAULT FALSE,
    "raw_title" TEXT UNIQUE NOT NULL,
    "culture" TEXT,
    "date_created" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE page_given_name_bridge(
    "id" SERIAL PRIMARY KEY,
    "pageid" INT REFERENCES wikipedia_page_ids(pageid) NOT NULL,
    "given_name_id" INT NOT NULL,
    "date_created" TIMESTAMP NOT NULL DEFAULT NOW() 
);

CREATE TABLE titles_without_matches(
    "id" SERIAL PRIMARY KEY,
    "pageid" INT NOT NULL UNIQUE,
    "title" TEXT NOT NULL,
    "date_created" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE page_meanings(
    "id" SERIAL PRIMARY KEY,
    "pageid" INT NOT NULL UNIQUE REFERENCES wikipedia_page_ids(pageid) ON DELETE CASCADE,
    "short_meaning" TEXT,
    "long_meaning" TEXT,
    "attempts" INT NOT NULL DEFAULT 0,
    "date_created" TIMESTAMP NOT NULL DEFAULT NOW()
)