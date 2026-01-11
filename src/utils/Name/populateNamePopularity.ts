import logWithTime from "../logWithTime"
import runSQL from "../runSQL";
import { resolve } from "path";

const dbSeedPath = '../../database/seed/'

export default async () => {
    try {
        logWithTime('Populating name_popularity_by_decade table...');
        const namePopularityByDecadePath = resolve(__dirname, dbSeedPath, 'namePopularityByDecade.sql')
        await runSQL(namePopularityByDecadePath);
        logWithTime('name_popularity_by_decade table populated.');
    } catch (err) {
        console.error('Error populating name_popularity_by_decade:', err);
        process.exit(1);
    }
}
