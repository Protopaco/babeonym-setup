import { query } from "./wikipool";

export default async (pageId: number): Promise<string | null> => {
  const result = await query(
    "SELECT * from get_temp_culture_category_by_pageid($1)",
    [pageId],
  );
  if (result.rows.length > 0) {
    return result.rows[0].raw_title;
  } else {
    return null;
  }
};
