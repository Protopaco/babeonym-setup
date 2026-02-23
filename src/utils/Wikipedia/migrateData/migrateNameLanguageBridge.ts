import wikipool from "../db/wikipool";

export default async () => {
  const nameMeaningPairs = await wikipool.query(
    `SELECT 
        plb.language_id,
        pgnb.given_name_id
    FROM page_language_bridge AS plb
    JOIN page_given_name_bridge AS pgnb
    ON pgnb.pageid = plb.pageid;
    `,
  );
  console.log(`migrating ${nameMeaningPairs.rows.length} pairs`);
  let count = 0;

  for await (const nameMeaningPair of nameMeaningPairs.rows) {
    const { given_name_id, language_id } = nameMeaningPair;
    await wikipool.query(
      `INSERT INTO given_name_language_bridge_staging (given_name_id, language_id)
        VALUES ($1, $2) ON CONFLICT DO NOTHING`,
      [given_name_id, language_id],
    );
    count++;
  }
  console.log(`migrated ${count} of ${nameMeaningPairs.rows.length}`);
};
