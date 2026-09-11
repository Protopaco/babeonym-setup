import { closePool, query } from "../../utils/postGresPool";
import fetchLanguageCodeModule from "../../sources/wiktionary/fetchLanguageCodeModule";

/**
 * Full languages first. If a code ever appears in both, the full-language name
 * is kept, since that is the one section headings use.
 */
const LANGUAGE_CODE_MODULES = [
  "Module:languages/code to canonical name",
  "Module:etymology languages/code to canonical name",
];

export default async () => {
  console.log("Refreshing Wiktionary language codes...");

  try {
    const entryByCode = new Map<
      string,
      { canonicalName: string; module: string }
    >();

    for (const moduleTitle of LANGUAGE_CODE_MODULES) {
      const entries = await fetchLanguageCodeModule(moduleTitle);

      for (const entry of entries) {
        if (!entryByCode.has(entry.code)) {
          entryByCode.set(entry.code, {
            canonicalName: entry.canonicalName,
            module: moduleTitle,
          });
        }
      }

      console.log(`  ${moduleTitle}: ${entries.length} codes`);
    }

    const codes = [...entryByCode.keys()];

    // One statement rather than nine thousand round trips.
    await query(
      `
        INSERT INTO wiktionary_language_codes (code, canonical_name, module, date_updated)
        SELECT unnested.code, unnested.canonical_name, unnested.module, NOW()
        FROM unnest($1::text[], $2::text[], $3::text[])
          AS unnested (code, canonical_name, module)
        ON CONFLICT (code) DO UPDATE
        SET canonical_name = EXCLUDED.canonical_name,
            module = EXCLUDED.module,
            date_updated = NOW()
      `,
      [
        codes,
        codes.map((code) => entryByCode.get(code)!.canonicalName),
        codes.map((code) => entryByCode.get(code)!.module),
      ],
    );

    console.log(`Stored ${codes.length} language codes.`);
  } finally {
    await closePool();
  }
};
