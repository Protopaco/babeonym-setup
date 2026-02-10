import { Pool, QueryResult } from "pg";
import dotenv from "dotenv";

dotenv.config();

const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: parseInt(process.env.DB_PORT || "5432"),
  database: process.env.WIKI_DB_NAME || "wikipedia",
  user: process.env.DB_USER || "paulstevens",
  password: process.env.DB_PASSWORD || undefined,
  max: 5, // maximum number of connections in pool
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Log pool errors
pool.on("error", (err) => {
  console.error("Unexpected error on idle client", err);
  process.exit(-1);
});

// Query function with error handling
export const query = async (
  text: string,
  params?: any[],
): Promise<QueryResult> => {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;

    // Only log errors and slow queries (> 1 second)
    if (duration > 1000) {
      console.warn(`Slow query (${duration}ms):`, text.substring(0, 100));
    }

    return res;
  } catch (error) {
    console.error("Database query error:", error);
    console.error("Query:", text);
    if (params) console.error("Params:", params);
    throw error;
  }
};

// Get a client from the pool for transactions
export const getClient = async () => {
  return await pool.connect();
};

// Close the pool (call this when your script finishes)
export const closePool = async () => {
  await pool.end();
  console.log("Database connection pool closed");
};

export default pool;
