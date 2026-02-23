import wikipool from "../db/wikipool";

export default async () => {
  console.log("migrate");
  const nameCulturePairs = await wikipool.query(
    `SELECT 
        pcb.culture_id,
        pgnb.given_name_id
    FROM page_culture_bridge AS pcb
    JOIN page_given_name_bridge AS pgnb
    ON pgnb.pageid = pcb.pageid;
    `,
  );
  console.log("🚀 ~ nameCulturePairs:", nameCulturePairs);
  console.log(`migrating ${nameCulturePairs.rows.length} pairs`);
  let count = 0;

  for await (const nameCulturePair of nameCulturePairs.rows) {
    const { given_name_id, culture_id } = nameCulturePair;
    await wikipool.query(
      `INSERT INTO given_name_culture_bridge_staging (given_name_id, culture_id)
        VALUES ($1, $2) ON CONFLICT DO NOTHING`,
      [given_name_id, culture_id],
    );
    count++;
  }
  console.log(`migrated ${count} of ${nameCulturePairs.rows.length}`);
};
