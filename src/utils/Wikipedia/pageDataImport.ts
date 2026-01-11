import { spawn } from "child_process";
import { join } from "path";

interface ImportOptions {
  testMode?: boolean; // If true, only import first 10000 lines
  database?: string;
  user?: string;
}

export async function importPagesPostgreSQL(
  options: ImportOptions = {}
) {
  const {
    testMode = false,
    database = process.env.DB_NAME || "babeonym",
    user = process.env.DB_USER || "paulstevens",
  } = options;

  const sqlFilePath = join(
    process.cwd(),
    "src/database/data/pages/enwiki-latest-page.sql.gz"
  );

  const testFilePath = "/tmp/test-pages.sql";
  const fileToImport = testMode
    ? testFilePath
    : sqlFilePath;

  console.log(
    testMode
      ? "Running test import (10000 lines)...\n"
      : "Running full pages import...\n"
  );

  // If test mode, create the test file first
  if (testMode) {
    console.log(
      "Creating test file from gzipped source..."
    );

    return new Promise((resolve, reject) => {
      const gunzip = spawn("gunzip", [
        "-c",
        sqlFilePath,
      ]);
      const head = spawn("head", ["-10000"]);
      const writeStream =
        require("fs").createWriteStream(
          testFilePath
        );

      gunzip.stdout.pipe(head.stdin);
      head.stdout.pipe(writeStream);

      head.on("close", async (code) => {
        if (code === 0) {
          console.log("Test file created\n");
          await runImport(
            testFilePath,
            database,
            user,
            false
          );
          resolve(true);
        } else {
          reject(
            new Error(
              `Failed to create test file, exit code: ${code}`
            )
          );
        }
      });

      gunzip.on("error", (err) =>
        reject(
          new Error(
            `gunzip error: ${err.message}`
          )
        )
      );
      head.on("error", (err) =>
        reject(
          new Error(`head error: ${err.message}`)
        )
      );
    });
  }

  // Run full import
  return runImport(
    sqlFilePath,
    database,
    user,
    true
  );
}

async function runImport(
  filePath: string,
  database: string,
  user: string,
  isGzipped: boolean
): Promise<boolean> {
  return new Promise((resolve, reject) => {
    const pv = spawn("pv", [filePath], {
      stdio: ["ignore", "pipe", "inherit"],
    });

    let processes: any[] = [pv];
    let lastStdout = pv.stdout;

    // Add gunzip if file is gzipped
    if (isGzipped) {
      const gunzip = spawn("gunzip", [], {
        stdio: ["pipe", "pipe", "inherit"],
      });
      pv.stdout.pipe(gunzip.stdin);
      lastStdout = gunzip.stdout;
      processes.push(gunzip);
    }

    // Pipe to PostgreSQL
    const psql = spawn(
      "psql",
      ["-U", user, "-d", database],
      {
        stdio: ["pipe", "inherit", "pipe"],
      }
    );

    lastStdout.pipe(psql.stdin);
    processes.push(psql);

    // Capture errors
    let errorOutput = "";
    psql.stderr.on("data", (data) => {
      errorOutput += data.toString();
      process.stderr.write(data);
    });

    psql.on("close", (code) => {
      if (code === 0) {
        console.log(
          "\n✅ Pages import completed successfully!"
        );
        resolve(true);
      } else {
        console.error("\n❌ Pages import failed");
        reject(
          new Error(
            `psql exit code: ${code}\n${errorOutput}`
          )
        );
      }
    });

    // Handle errors for all processes
    processes.forEach((proc, index) => {
      proc.on("error", (err: Error) => {
        const names = ["pv", "gunzip", "psql"];
        reject(
          new Error(
            `${names[index]} error: ${err.message}`
          )
        );
      });
    });
  });
}
