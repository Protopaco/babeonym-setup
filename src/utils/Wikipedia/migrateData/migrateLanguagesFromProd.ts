import wikipool from "../db/wikipool";
import pgpool from "../../postGresPool";

export default async () => {
  const languages = await pgpool.query("SELECT * FROM languages");
  console.log(`🚀 ~ migrating ${languages.rows.length} languages`);
  let count = 0;
  for (const language of languages.rows) {
    const { id, label, flag } = language;
    await wikipool.query(
      "INSERT INTO languages_staging (id, label, flag) VALUES ($1, $2, $3) ON CONFLICT (id) DO UPDATE SET label = EXCLUDED.label, flag = EXCLUDED.flag",
      [id, label, flag],
    );
    count++;
  }
  console.log(`🚀 ~ migrated ${count} of ${languages.rows.length} languages`);
};
