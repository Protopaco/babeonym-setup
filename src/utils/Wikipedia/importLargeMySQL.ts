import { spawn } from "node:child_process";
import fs from "node:fs";

export default async (filePath: string) => {
    return new Promise<void>((resolve, reject) => {
        // Add -pYOURPASS if needed, or use env var MYSQL_PWD (below)
        const mysql = spawn("mysql", ["-h", "127.0.0.1", "-P", "3306", "-u", "root", "wikipedia"], {
            stdio: ["pipe", "pipe", "pipe"],
            env: {
                ...process.env,
                // Safer than putting -p on the command line history:
                // MYSQL_PWD: process.env.MYSQL_PASSWORD ?? "",
            },
        });

        fs.createReadStream(filePath).pipe(mysql.stdin);

        let stderr = "";
        mysql.stderr.on("data", (d) => (stderr += d.toString()));

        mysql.on("close", (code) => {
            if (code === 0) return resolve();
            reject(new Error(`mysql exited ${code}\n${stderr}`));
        });

        mysql.on("error", reject);
    });
}
