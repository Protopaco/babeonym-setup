import logWithTime from "../logWithTime"
import fs from 'fs';
import path from 'path';
import { query } from "../pool";

const dbNamePath = path.join(__dirname, '../../database/data/names/');

export default async () => {
    logWithTime('Inserting occurrences from files...');
    try {
        const files = fs.readdirSync(dbNamePath).filter((f) => /^yob\d{4}\.txt$/.test(f));

        for (const file of files) {
            const match = file.match(/^yob(\d{4})\.txt$/);
            if (!match) continue;

            const year = parseInt(match[1], 10);
            logWithTime(`Processing occurrences for year: ${year} from file: ${file}`);

            const filePath = path.join(dbNamePath, file);
            const lines = fs.readFileSync(filePath, 'utf8').split('\n').filter(Boolean);

            // Parse all records
            const items = lines.map((line) => {
                const [name, gender, count] = line.split(',');
                return {
                    name,
                    gender: gender === 'M' ? 'Male' : 'Female',
                    count: parseInt(count, 10)
                };
            });

            // Process in batches of 1000
            for (let i = 0; i < items.length; i += 1000) {
                const batch = items.slice(i, i + 1000);

                const names = batch.map(item => item.name);
                const genders = batch.map(item => item.gender);
                const counts = batch.map(item => item.count);

                await query(
                    'SELECT insert_name_occurrences($1, $2, $3, $4)',
                    [year, names, genders, counts]
                );

                logWithTime(`  Processed ${Math.min(i + 1000, items.length)}/${items.length} records`);
            }

            logWithTime(`Occurrences for year ${year} inserted.`);
        }

        logWithTime('All name occurrences inserted successfully.');
    } catch (err) {
        console.error('Error inserting occurrences from files:', err);
        process.exit(1);
    }
}
