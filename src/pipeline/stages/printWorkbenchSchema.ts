import workbenchSqlFiles from "../utils/workbenchSqlFiles";

export default async () => {
  console.log("Workbench SQL files, in run order:");
  for (const sqlFile of workbenchSqlFiles) {
    console.log(`  ${sqlFile}`);
  }
};
