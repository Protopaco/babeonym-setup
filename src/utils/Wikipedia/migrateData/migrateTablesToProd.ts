import wikipool from "../db/wikipool";
import pgpool from "../../postGresPool";

export default async () => {
  //   const { rows } = await wikipool.query(
  //     `SELECT * FROM language_region_bridge_staging`,
  //   );

  //   console.log(`🚀 ~ migrating ${rows.length} pairs`);
  //   let count = 0;
  //   for (const languageRegionPair of rows) {
  //     const { language_id, region_id } = languageRegionPair;
  //     await pgpool.query(
  //       `INSERT INTO language_region_bridge(language_id, region_id) VALUES($1, $2) ON CONFLICT DO NOTHING`,
  //       [language_id, region_id],
  //     );
  //     count++;
  //   }
  //   console.log(`migrated ${count}`);

  //   const { rows } = await wikipool.query(
  //     `SELECT * FROM given_name_meaning_staging`,
  //   );
  //   console.log(`🚀 ~ migrating ${rows.length} pairs`);
  //   let count = 0;
  //   for (const givenNameMeaning of rows) {
  //     const { given_name_id, meaning_short, meaning_long } = givenNameMeaning;
  //     await pgpool.query(
  //       `INSERT INTO given_name_meaning(given_name_id, meaning_short, meaning_long)
  //       VALUES ($1, $2, $3) ON CONFLICT DO NOTHING`,
  //       [given_name_id, meaning_short, meaning_long],
  //     );
  //     count++;
  //   }
  //   console.log(`migrated ${count} of ${rows.length}`);

  //   const { rows } = await wikipool.query(
  //     `SELECT * FROM given_name_culture_bridge_staging`,
  //   );
  //   console.log(`🚀 ~ migrating ${rows.length} pairs`);
  //   let count = 0;
  //   for (const givenNameCulture of rows) {
  //     const { given_name_id, culture_id } = givenNameCulture;
  //     await pgpool.query(
  //       `INSERT INTO given_name_culture_bridge(given_name_id, culture_id)
  //         VALUES($1, $2) ON CONFLICT DO NOTHING
  //         `,
  //       [given_name_id, culture_id],
  //     );
  //     count++;
  //   }
  //   console.log(`migrated ${count} of ${rows.length}`);
  //
  const { rows } = await wikipool.query(
    `SELECT * FROM given_name_language_bridge_staging`,
  );
  console.log(`🚀 ~ migrating ${rows.length} pairs`);
  let count = 0;
  for (const givenNameLanguage of rows) {
    const { given_name_id, language_id } = givenNameLanguage;
    await pgpool.query(
      `INSERT INTO given_name_language_bridge(given_name_id, language_id) 
        VALUES($1, $2) ON CONFLICT DO NOTHING
        `,
      [given_name_id, language_id],
    );
    count++;
  }
  console.log(`migrated ${count} of ${rows.length}`);
};
