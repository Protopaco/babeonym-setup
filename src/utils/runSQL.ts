import { readFileSync } from "fs";
import { query } from "./postGresPool";

export default async (sqlPath: string) => {
  const sql = readFileSync(sqlPath, "utf-8");
  const result = await query(sql);
  return result;
};
