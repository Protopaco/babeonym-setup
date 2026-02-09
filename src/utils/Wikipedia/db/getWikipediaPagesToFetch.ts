import { query } from "./wikipool";

export default async (limit: number, maxHits: number): Promise<number[]> => {
  console.log(
    `Fetching Wikipedia pages to fetch with limit ${limit} and maxHits ${maxHits}`,
  );
  try {
    const result = await query(
      "SELECT * FROM get_wikipedia_pages_to_fetch($1, $2)",
      [limit, maxHits],
    );
    return result.rows.map((row) => row.out_pageid);
  } catch (error) {
    console.error("Error fetching Wikipedia pages to fetch:", error);
    return [];
  }
};
