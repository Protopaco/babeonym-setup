import mysql from "mysql2/promise";
import dotenv from "dotenv";

dotenv.config();

const pool = mysql.createPool({
    host: process.env.MYSQL_HOST || "localhost",
    port: parseInt(process.env.MYSQL_PORT || "3306"),
    database: process.env.MYSQL_DB || "wikipedia",
    user: process.env.MYSQL_USER || "root",
    password: process.env.MYSQL_PASSWORD || '',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    enableKeepAlive: true,
    keepAliveInitialDelay: 0,
});

// Query function with error handling
export const query = async (
    sql: string,
    params?: any[]
): Promise<any> => {

    console.log("🚀 ~ process.env.MYSQL_HOST :", process.env)
    const start = Date.now();
    try {
        const [rows] = await pool.query(sql, params);
        const duration = Date.now() - start;

        // Log slow queries (> 1 second)
        if (duration > 1000) {
            console.warn(
                `Slow MySQL query (${duration}ms):`,
                sql.substring(0, 100)
            );
        }

        return rows;
    } catch (error) {
        console.error("MySQL query error:", error);
        console.error("Query:", sql);
        if (params) console.error("Params:", params);
        throw error;
    }
};

// Get a connection from the pool for transactions
export const getConnection = async () => {
    return await pool.getConnection();
};

// Close the pool (useful for graceful shutdown)
export const closePool = async () => {
    await pool.end();
    console.log("MySQL connection pool closed");
};

export default pool;