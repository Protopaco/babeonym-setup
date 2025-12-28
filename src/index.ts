import dotenv from 'dotenv';
import { startCLI } from './cli/menu';

// Load environment variables
dotenv.config();

async function main() {
  try {
    console.log('🚀 Babeonym Database Setup Tool\n');
    await startCLI();
  } catch (error) {
    console.error('❌ Fatal error:', error);
    process.exit(1);
  }
}

main();
