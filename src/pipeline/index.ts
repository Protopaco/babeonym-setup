type PipelineCommand = {
  description: string;
  run: () => Promise<void>;
};

const commands: Record<string, PipelineCommand> = {
  "evidence:list-names": {
    description: "Read a small batch of existing given names.",
    run: async () => {
      const listNamesModule = (await import(
        "./stages/listNames.js"
      )) as unknown as { default: () => Promise<void> };
      await listNamesModule.default();
    },
  },
  "wiktionary:fetch": {
    description: "Fetch raw Wiktionary evidence for existing given names.",
    run: async () => {
      const fetchWiktionaryModule = (await import(
        "./stages/fetchWiktionary.js"
      )) as unknown as { default: () => Promise<void> };
      await fetchWiktionaryModule.default();
    },
  },
  "wiktionary:extract-claims": {
    description: "Extract conservative candidate claims from stored Wiktionary evidence.",
    run: async () => {
      const extractWiktionaryClaimsModule = (await import(
        "./stages/extractWiktionaryClaims.js"
      )) as unknown as { default: () => Promise<void> };
      await extractWiktionaryClaimsModule.default();
    },
  },
  "wikidata:refresh-types": {
    description:
      "Resolve everything Wikidata treats as a given name, so batch queries can skip the subclass walk.",
    run: async () => {
      const refreshWikidataTypesModule = (await import(
        "./stages/refreshWikidataTypes.js"
      )) as unknown as { default: () => Promise<void> };
      await refreshWikidataTypesModule.default();
    },
  },
  "wikidata:fetch": {
    description: "Fetch raw Wikidata evidence for existing given names.",
    run: async () => {
      const fetchWikidataModule = (await import(
        "./stages/fetchWikidata.js"
      )) as unknown as { default: () => Promise<void> };
      await fetchWikidataModule.default();
    },
  },
  "wikidata:extract-claims": {
    description:
      "Extract language, gender and relationship claims from stored Wikidata evidence.",
    run: async () => {
      const extractWikidataClaimsModule = (await import(
        "./stages/extractWikidataClaims.js"
      )) as unknown as { default: () => Promise<void> };
      await extractWikidataClaimsModule.default();
    },
  },
  "meanings:normalise": {
    description:
      "Put both meaning sources through one normaliser into workbench candidates.",
    run: async () => {
      const normaliseMeaningsModule = (await import(
        "./stages/normaliseMeanings.js"
      )) as unknown as { default: () => Promise<void> };
      await normaliseMeaningsModule.default();
    },
  },
  "workbench:init": {
    description: "Create and seed the additive data-generation workbench tables.",
    run: async () => {
      const initWorkbenchModule = (await import(
        "./stages/initWorkbench.js"
      )) as unknown as { default: () => Promise<void> };
      await initWorkbenchModule.default();
    },
  },
  "workbench:print-schema": {
    description: "Print the workbench SQL files in run order.",
    run: async () => {
      const printWorkbenchSchemaModule = (await import(
        "./stages/printWorkbenchSchema.js"
      )) as unknown as { default: () => Promise<void> };
      await printWorkbenchSchemaModule.default();
    },
  },
};

const printHelp = () => {
  console.log("Babeonym data pipeline\n");
  console.log("Usage:");
  console.log("  npm run pipeline -- <command>\n");
  console.log("Commands:");
  for (const [command, config] of Object.entries(commands).sort()) {
    console.log(`  ${command} - ${config.description}`);
  }
};

const main = async () => {
  const command = process.argv[2];

  if (!command || command === "--help" || command === "-h") {
    printHelp();
    return;
  }

  const commandConfig = commands[command];
  if (!commandConfig) {
    console.error(`Unknown pipeline command: ${command}\n`);
    printHelp();
    process.exit(1);
  }

  await commandConfig.run();
};

main().catch((error) => {
  console.error("Pipeline failed:", error);
  process.exit(1);
});
