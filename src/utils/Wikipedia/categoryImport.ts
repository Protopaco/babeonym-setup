import { spawn } from "child_process";
import { join } from "path";

interface ImportOptions {
  testMode?: boolean; // If true, only import first 1000 lines
  database?: string;
  user?: string;
}

export default async function importCategoryLinksMySQL(
  options: ImportOptions = {}
) {
  const {
    testMode = false,
    database = "wikipedia",
    user = "root",
  } = options;

  const sqlFilePath = join(
    process.cwd(),
    "src/database/data/catagories/enwiki-latest-categorylinks.sql"
  );

  const testFilePath =
    "/tmp/test-categorylinks.sql";
  const fileToImport = testMode
    ? testFilePath
    : sqlFilePath;

  console.log(
    testMode
      ? "Running test import (1000 lines)...\n"
      : "Running full import...\n"
  );

  // If test mode, create the test file first
  if (testMode) {
    console.log("Creating test file...");
    const head = spawn("head", [
      "-1000",
      sqlFilePath,
    ]);
    const writeStream =
      require("fs").createWriteStream(
        testFilePath
      );

    head.stdout.pipe(writeStream);

    await new Promise((resolve, reject) => {
      head.on("close", (code) => {
        if (code === 0) {
          console.log("Test file created\n");
          resolve(true);
        } else {
          reject(
            new Error(
              `Failed to create test file, exit code: ${code}`
            )
          );
        }
      });
    });
  }

  // Run pv | mysql
  return new Promise((resolve, reject) => {
    const pv = spawn("pv", [fileToImport], {
      stdio: ["ignore", "pipe", "inherit"],
    });
    const mysql = spawn(
      "mysql",
      ["-u", user, database],
      {
        stdio: ["pipe", "inherit", "pipe"],
      }
    );

    // Pipe pv stdout to mysql stdin
    pv.stdout.pipe(mysql.stdin);

    // Capture mysql errors
    let errorOutput = "";
    mysql.stderr.on("data", (data) => {
      errorOutput += data.toString();
      process.stderr.write(data);
    });

    mysql.on("close", (code) => {
      if (code === 0) {
        console.log(
          "\n✅ Import completed successfully!"
        );
        resolve(true);
      } else {
        console.error("\n❌ Import failed");
        reject(
          new Error(
            `MySQL exit code: ${code}\n${errorOutput}`
          )
        );
      }
    });

    pv.on("error", (err) => {
      reject(
        new Error(`pv error: ${err.message}`)
      );
    });

    mysql.on("error", (err) => {
      reject(
        new Error(`mysql error: ${err.message}`)
      );
    });
  });
}
