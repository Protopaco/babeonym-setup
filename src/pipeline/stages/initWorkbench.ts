import runWorkbenchSQL from "../utils/runWorkbenchSQL";
import workbenchSqlFiles from "../utils/workbenchSqlFiles";
import { closePool } from "../../utils/postGresPool";

export default async () => {
  console.log("Initializing data generation workbench...");
  try {
    for (const sqlFile of workbenchSqlFiles) {
      await runWorkbenchSQL(sqlFile);
    }
    console.log("Data generation workbench initialized.");
  } finally {
    await closePool();
  }
};
