import { readFileSync } from "fs";
import { query } from "../../utils/postGresPool";
import logWithTime from "../../utils/logWithTime";

export default async (sqlPath: string) => {
  logWithTime(`Executing workbench SQL file: ${sqlPath}`);
  const sql = readFileSync(sqlPath, "utf-8");
  return query(sql);
};
