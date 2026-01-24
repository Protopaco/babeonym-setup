import fs from 'fs';
import readline from 'readline';
import pool from './mysqlPool';


export default async (filePath: string) => {

    const fileStream = fs.createReadStream(filePath);
    const rl = readline.createInterface({
        input: fileStream,
        crlfDelay: Infinity
    });

    let statement = '';
    let statementCount = 0;

    for await (const line of rl) {
        if (line.trim().startsWith('--') || line.trim() === '') continue;
        statement += line + '\n';
        if (line.trim().endsWith(';')) {
            try {
                await pool.query(statement);
                statementCount++;
                if (statementCount % 10 === 0) {
                    console.log(`Executed ${statementCount} statements...`);
                }
            } catch (err) {
                console.error('Error executing statement:', err);
            }
            statement = '';
        }
    }
    console.log(`Import complete! Total statements executed: ${statementCount}`);


}