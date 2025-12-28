# Babeonym Setup

Database setup tool for the Babeonym application. This tool extracts, processes, and loads name data from various sources into a PostgreSQL database.

## Features

- Extract name information from text files
- Extract Wikipedia categories
- Parse Wikipedia dumps for given name definitions
- Process gender, popularity, origin, and other name attributes
- Create and manage database schema

## Setup

1. Install dependencies:

```bash
npm install
```

2. Copy `.env.example` to `.env` and configure your database connection:

```bash
cp .env.example .env
```

3. Build the project:

```bash
npm run build
```

## Usage

Run the interactive CLI:

```bash
npm start
```

Or run in development mode:

```bash
npm run dev
```

## Project Structure

```
src/
├── cli/              # Interactive CLI using Inquirer.js
├── extractors/       # Data extraction from various sources
├── processors/       # Data processing and transformation
├── database/         # Database schema, migrations, and functions
├── utils/            # Utility functions
└── types/            # TypeScript type definitions

data/
├── raw/              # Raw input data
│   ├── names/        # Name text files
│   └── wiki-dumps/   # Wikipedia dump files
└── processed/        # Intermediate processed data
```

## Development

- `npm run dev` - Run in development mode with ts-node
- `npm run build` - Compile TypeScript to JavaScript
- `npm run typecheck` - Check types without emitting files
- `npm test` - Run tests
