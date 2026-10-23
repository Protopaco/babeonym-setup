# Babeonym setup

The database and the name data behind [Babeonym](https://www.babeonym.com), an app that helps parents choose a baby name by comparing names two at a time.

Babeonym is three repositories:

- [babeonym-frontend](https://github.com/Protopaco/babeonym-frontend): the React app.
- [babeonym-backend](https://github.com/Protopaco/babeonym-backend): the API.
- **babeonym-setup**: this repository, the PostgreSQL schema and the pipeline that builds the name data.

## What it does

- Holds the PostgreSQL schema, functions and seed data the backend reads, as numbered SQL files run in order.
- Builds the names, with their gender and popularity by decade, from the US Social Security year-of-birth files.
- Adds meaning, language and culture from Wikipedia, Wiktionary and Wikidata.

## Built with

TypeScript run with tsx, PostgreSQL, MySQL for the Wikipedia import, wtf_wikipedia for reading Wikipedia pages, and Inquirer for the menu.

## Setting up

1. Copy `.env.example` to `.env` and fill it in: the PostgreSQL connection, the MySQL connection for the Wikipedia import, a contact address for Wikimedia requests, and the paths to the [Wikipedia dump](https://dumps.wikimedia.org/) and the [Social Security name data](https://www.ssa.gov/oact/babynames/index.html).
2. `npm install`

## Building the database

`npm run dev` opens a menu. **Names → Spin Up Database** runs every file in `src/database/postGres` in order, then seeds the name tables and fills in their popularity. The **Wikipedia** menu runs the Wikipedia import one step at a time.

## The data pipeline

`npm run pipeline <command>` runs one stage of the data pipeline. It fetches evidence from Wiktionary and Wikidata into a separate workbench, extracts claims from it, and publishes the confident results into the tables the app reads. Run `npm run pipeline` on its own to list the stages.

The thinking behind the data is in [`docs/data-generation-plan.md`](docs/data-generation-plan.md) and [`docs/data-generation-decisions.md`](docs/data-generation-decisions.md), including what each source actually contains.

## Layout

- `src/database/postGres`: the schema, functions and seeds, numbered in run order. A later version of a file replaces an earlier one.
- `src/database/workbench`: the workbench tables and the review decisions seeded into them.
- `src/database/reports`: SQL reports on coverage and on where the sources disagree.
- `src/pipeline`: the pipeline's stages.
- `src/sources`: the Wiktionary and Wikidata clients and claim extraction.
- `src/utils`: the menu's tasks, including the Wikipedia import.
