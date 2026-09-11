import path from "path";

const workbenchBasePath = path.resolve(__dirname, "../../database/workbench");

const workbenchSqlFiles = [
  "001_data_generation_workbench.v1.sql",
  "002_seed_data_sources.v1.sql",
  "003_round_one_additions.v1.sql",
  "004_seed_language_alias_decisions.v1.sql",
  "005_seed_round_one_language_decisions.v1.sql",
  "006_normalised_meaning_candidates.v1.sql",
  "007_seed_wikidata_language_item_decisions.v1.sql",
].map((fileName) => path.join(workbenchBasePath, fileName));

export default workbenchSqlFiles;
