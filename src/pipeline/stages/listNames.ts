import { closePool, query } from "../../utils/postGresPool";
import getPositiveIntArg from "../utils/getPositiveIntArg";

type GivenNameRow = {
  id: number;
  given_name: string;
};

export default async () => {
  const limit = getPositiveIntArg("--limit", 25, 500);

  try {
    const result = await query(
      `
        SELECT id, given_name
        FROM given_names
        ORDER BY id
        LIMIT $1
      `,
      [limit],
    );

    console.log(`First ${result.rows.length} given names:`);
    for (const row of result.rows as GivenNameRow[]) {
      console.log(`  ${row.id}: ${row.given_name}`);
    }
  } finally {
    await closePool();
  }
};
