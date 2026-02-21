import { query } from "./wikipool";

export default async (limit: number): Promise<number[]> => {
  console.log("🚀 ~ limit:", limit);
  const result = await query("SELECT * from get_pages_need_meanings($1)", [
    limit,
  ]);
  return result.rows.map((row) => row.out_pageid);
};
