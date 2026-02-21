import wikipool from "../db/wikipool";
import pgpool from "../../postGresPool";

export default async () => {
  const regions = await pgpool.query("SELECT * FROM regions");
  console.log(`🚀 ~ migrating ${regions.rows.length} regions`);
  let count = 0;
  for (const region of regions.rows) {
    const { id, label, parent_id } = region;
    await wikipool.query(
      "INSERT INTO regions_staging (id, label, parent_id) VALUES ($1, $2, $3) ON CONFLICT (id) DO UPDATE SET label = EXCLUDED.label, parent_id = EXCLUDED.parent_id",
      [id, label, parent_id],
    );
    count++;
  }
  console.log(`🚀 ~ migrated ${count} of ${regions.rows.length} regions`);
};
