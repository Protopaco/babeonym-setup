// import fs from 'fs/promises';
// import pool from '../mysqlPool';

// /**
//  * Reads a SQL query from a file, runs it, and stores results in import_queries and pages_to_import.
//  * @param filePath - Path to the SQL file containing the query.
//  * @param description - Optional description for the query.
//  * @returns The import_queries row ID and number of pages imported.
//  */
// export default async (filePath: string, description?: string) => {
//     // Read query from file
//     const queryText = await fs.readFile(filePath, 'utf8');

//     // Run the query to get pageIds
//     const pageRows = await pool.query(queryText);
//     const pageIds = pageRows[0].map((row: any) => row.page_id);

//     // Insert the query into import_queries
//     const [result] = await pool.query(
//         'INSERT INTO import_queries (query_text, description, pages_found) VALUES (?, ?, ?)',
//         [queryText, description || '', pageIds.length]
//     );
//     const queryId = result.insertId;

//     // Insert pageIds into pages_to_import
//     if (pageIds.length > 0) {
//         const values = pageIds.map(id => [id, queryId]);
//         await pool.query(
//             'INSERT IGNORE INTO pages_to_import (page_id, query_id) VALUES ?',
//             [values]
//         );
//     }

//     return { queryId, pagesImported: pageIds.length };
// }
