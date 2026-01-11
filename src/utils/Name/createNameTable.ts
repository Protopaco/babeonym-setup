import { resolve } from 'path';
import runSQL from '../runSQL';
import logWithTime from '../logWithTime';

const dbSchemaPath = '../../database/schemas/'
const dbSeedPath = '../../database/seed/'


export default async function deployBabeonymSchema(): Promise<void> {
    try {

        const dropTables = resolve(__dirname, dbSeedPath, 'dropTables.sql');
        logWithTime('Dropping existing tables if any...');
        await runSQL(dropTables);

        const schemaPath = resolve(__dirname, dbSchemaPath, 'babeonym_schema.sql');
        logWithTime('Deploying Babeonym schema...');
        await runSQL(schemaPath);

        const insertNameOccurrencesPath = resolve(__dirname, dbSeedPath, 'functions', 'insertNameOccurences.sql');
        logWithTime('Deploying insert name occurrences function');
        await runSQL(insertNameOccurrencesPath);

        console.log('Babeonym schema deployed successfully');
    } catch (error) {
        console.error('Error deploying Babeonym schema:', error);
        throw error;
    }
}