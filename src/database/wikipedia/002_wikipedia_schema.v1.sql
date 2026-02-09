DROP TABLE IF EXISTS wikipedia_page_raw CASCADE;
DROP TABLE IF EXISTS wikipedia_page_ids CASCADE;

CREATE TABLE wikipedia_page_ids(
    "id" SERIAL PRIMARY KEY,
    "source" TEXT NOT NULL,
    "pageid" INT UNIQUE NOT NULL,
    "title" TEXT NOT NULL,
    "ns" INT NOT NULL,
    "hits" INT NOT NULL DEFAULT 0,
    "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
    "date_updated" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE wikipedia_page_raw(
    "id" SERIAL PRIMARY KEY,
    "pageid" INT UNIQUE REFERENCES wikipedia_page_ids(pageid) ON DELETE CASCADE,
    "raw_content" TEXT NOT NULL,
    "date_created" TIMESTAMP NOT NULL DEFAULT NOW(),
    "date_updated" TIMESTAMP NOT NULL DEFAULT NOW()

);