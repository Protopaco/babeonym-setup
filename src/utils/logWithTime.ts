import fs from 'fs';
import path from 'path';

export default (message: string) => {
    // Get date in YYYY-MM-DD format for daily log files
    const today = new Date().toISOString().split('T')[0];

    // Ensure logs directory exists
    const logsDir = path.resolve(__dirname, './logs');
    if (!fs.existsSync(logsDir)) {
        fs.mkdirSync(logsDir, { recursive: true });
    }

    const logFile = path.resolve(logsDir, `seedDatabase.${today}.log`);
    const now = new Date().toISOString();
    const line = `[${now}] ${message}`;

    console.log(line);
    fs.appendFileSync(logFile, line + '\n');
}