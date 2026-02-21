import wikipool from "../db/wikipool";
import pgpool from "../../postGresPool";

export default async () => {
  const meanings = await wikipool.query(`SELECT 
                    pm.id, pm.long_meaning, pm.short_meaning, pgnb.given_name_id 
                    FROM page_meanings as pm
                    JOIN page_given_name_bridge as pgnb ON pm.pageid = pgnb.pageid
                    WHERE long_meaning IS NOT NULL
                    OR short_meaning IS NOT NULL;`);
  console.log(`🚀 ~ migrating ${meanings.rows.length} meanings`);
  let count = 0;
  for (const meaning of meanings.rows) {
    const { long_meaning, short_meaning, given_name_id } = meaning;
    await wikipool.query(
      `INSERT INTO given_name_meaning_staging (meaning_long, meaning_short, given_name_id) 
      VALUES ($1, $2, $3) ON CONFLICT DO NOTHING `,
      [long_meaning, short_meaning, given_name_id],
    );
    count++;
  }
  console.log(`🚀 ~ migrated ${count} of ${meanings.rows.length} meanings`);
};
