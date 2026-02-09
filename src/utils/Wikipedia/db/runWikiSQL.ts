import { readFileSync } from "fs";
import { query } from "./wikipool";
import logWithTime from "../../logWithTime";

export default async (sqlPath: string) => {
  logWithTime(`Executing SQL file: ${sqlPath}`);
  const sql = readFileSync(sqlPath, "utf-8");
  const result = await query(sql);
  return result;
};
