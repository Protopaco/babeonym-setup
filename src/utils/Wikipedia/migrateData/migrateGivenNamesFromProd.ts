import wikipool from "../db/wikipool";
import pgpool from "../../postGresPool";

export default async () => {
  const givenNames = await pgpool.query("SELECT * FROM given_names");
  console.log(`🚀 ~ migrating ${givenNames.rows.length} given names`);
  let count = 0;
  for (const givenName of givenNames.rows) {
    const { id, given_name } = givenName;
    await wikipool.query(
      "INSERT INTO given_names_staging (id, given_name) VALUES ($1, $2) ON CONFLICT (id) DO UPDATE SET given_name = EXCLUDED.given_name",
      [id, given_name],
    );
    count++;
  }
  console.log(
    `🚀 ~ migrated ${count} of ${givenNames.rows.length} given names`,
  );
};
