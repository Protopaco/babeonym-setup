import { query } from "./wikipool";

export type UnbridgedPageInfo = {
  pageid: number;
  title: string | null;
  resolved_title: string | null;
  resolved_pageid: number | null;
};

export default async (limit: number): Promise<UnbridgedPageInfo[]> => {
  const res = await query(
    `SELECT * FROM get_unbridged_pageids_with_no_title($1);`,
    [limit],
  );
  return res.rows.map((row) => ({
    pageid: row.pageid,
    title: row.title,
    resolved_title: row.resolved_title,
    resolved_pageid: row.resolved_pageid,
  }));
};
