import wikipool from "../db/wikipool";
import pgpool from "../../postGresPool";

export default async () => {
  const cultures = await pgpool.query("SELECT * FROM cultures");
  console.log(`🚀 ~ migrating ${cultures.rows.length} cultures`);
  let count = 0;
  for (const culture of cultures.rows) {
    const { id, label } = culture;
    await wikipool.query(
      "INSERT INTO cultures_staging (id, label) VALUES ($1, $2) ON CONFLICT (id) DO UPDATE SET label = EXCLUDED.label",
      [id, label],
    );
    count++;
  }
  console.log(`🚀 ~ migrated ${count} of ${cultures.rows.length} cultures`);
};
