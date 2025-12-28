export const databaseConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'babeonym',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
};

export const paths = {
  wikiDump: process.env.WIKI_DUMP_PATH || './data/raw/wiki-dumps',
  namesData: process.env.NAMES_DATA_PATH || './data/raw/names',
  processedData: process.env.PROCESSED_DATA_PATH || './data/processed',
};
