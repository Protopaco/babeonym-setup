import { spawn } from "child_process";
import { join } from "path";

interface ImportOptions {
  database?: string;
  user?: string;
}

export async function importPagesMySQL(
  options: ImportOptions = {}
) {
  const {
    database = "wikipedia",
    user = "root",
  } = options;

  const sqlFilePath = join(
    process.cwd(),
    "src/database/data/pages/enwiki-latest-page.sql.gz"
  );

  console.log("Running pages import...\n");

  return new Promise((resolve, reject) => {
    // Spawn: pv file.sql.gz | gunzip | mysql
    const pv = spawn("pv", [sqlFilePath], {
      stdio: ["ignore", "pipe", "inherit"],
    });

    const gunzip = spawn("gunzip", [], {
      stdio: ["pipe", "pipe", "inherit"],
    });

    const mysql = spawn(
      "mysql",
      ["-u", user, database],
      {
        stdio: ["pipe", "inherit", "pipe"],
      }
    );

    // Chain: pv -> gunzip -> mysql
    pv.stdout.pipe(gunzip.stdin);
    gunzip.stdout.pipe(mysql.stdin);

    let errorOutput = "";
    mysql.stderr.on("data", (data) => {
      errorOutput += data.toString();
      process.stderr.write(data);
    });

    mysql.on("close", (code) => {
      if (code === 0) {
        console.log(
          "\n✅ Pages import completed successfully!"
        );
        resolve(true);
      } else {
        console.error("\n❌ Pages import failed");
        reject(
          new Error(
            `MySQL exit code: ${code}\n${errorOutput}`
          )
        );
      }
    });

    pv.on("error", (err) =>
      reject(
        new Error(`pv error: ${err.message}`)
      )
    );
    gunzip.on("error", (err) =>
      reject(
        new Error(`gunzip error: ${err.message}`)
      )
    );
    mysql.on("error", (err) =>
      reject(
        new Error(`mysql error: ${err.message}`)
      )
    );
  });
}
