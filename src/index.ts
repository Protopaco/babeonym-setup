import inquirer from "inquirer";
import createNameTable from "./utils/Name/createNameTable";
import populateNamePopularity from "./utils/Name/populateNamePopularity";
import seedNameTables from "./utils/Name/seedNameTables";
import importLargeSQL from "./utils/importLargeSQL";


const basePath = "/Volumes/Babeonym/Babeonym/babeonym-setup/src/database/data/wikipedia/"
const wikipediaFiles = [
  { name: "Create Query Tables", fileName: "wikipedia_schema.sql" },
  { name: "Seed All Titles Table", fileName: "enwiki-latest-all-titles.sql" },
  { name: "Seed Categories Table", fileName: "enwiki-latest-category.sql" },
  { name: "Seed Category Links Table", fileName: "enwiki-latest-categorylinks.sql" },
  { name: "Seed Page Props Table", fileName: "enwiki-latest-page_props.sql" },
  { name: "Seed Redirect Table", fileName: "enwiki-latest-redirect.sql" },
  { name: "Seed Page Links Table", fileName: "enwiki-latest-pagelinks.sql" },
  { name: "Seed Pages Table", fileName: "enwiki-latest-pages-articles.sql" },
]
console.log("Welcome to the Babeonym Setup!\n");
const main = async () => {
  let exit = false;

  while (!exit) {
    const { mainChoice } = await inquirer.prompt([
      {
        type: "select",
        name: "mainChoice",
        message: "What would you like to do?",
        choices: ["Wikipedia", "Names", "Exit"],
      },
    ]);

    switch (mainChoice) {
      case "Wikipedia":
        await wikipediaMenu();
        break;
      case "Names":
        await namesMenu();
        break;
      case "Exit":
        exit = true;
        console.log("\nGoodbye!");
        break;
    }
  }


  async function wikipediaMenu() {
    const { action } = await inquirer.prompt([
      {
        type: "select",
        name: "action",
        message:
          "Wikipedia Categories - Select action:",
        choices: wikipediaFiles.map(file => file.name)
      },
    ]);

    const choice = wikipediaFiles.find(file => file.name === action);
    if (choice) {
      await importLargeSQL(basePath + choice.fileName);
    }
    else { console.log("Invalid choice"); }

  }
}

async function wikipediaArticlesMenu() {
  const { action } = await inquirer.prompt([
    {
      type: "select",
      name: "action",
      message:
        "Wikipedia Articles - Select action:",
      choices: [
        "Generate article tables",
        "Seed article data",
        "Back to main menu",
      ],
    },
  ]);

  switch (action) {
    case "Generate article tables":
      console.log(
        "\n→ Generating article tables..."
      );
      // Your function will go here
      break;
    case "Seed article data":
      console.log("\n→ Seeding article data...");
      // Your function will go here
      break;
    case "Back to main menu":
      return;
  }

}

async function namesMenu() {
  const { action } = await inquirer.prompt([
    {
      type: "select",
      name: "action",
      message: "Names - Select action:",
      choices: [
        "Generate name tables",
        "Seed name tables",
        "Generate name popularity",
        "Back to main menu",
      ],
    },
  ]);

  switch (action) {
    case "Generate name tables":
      console.log(
        "\n→ Generating name tables..."
      );
      await createNameTable();
      break;
    case "Seed name tables":
      console.log("\n→ Seeding name tables...");
      await seedNameTables();
      break;
    case "Generate name popularity":
      console.log(
        "\n→ Generating name popularity..."
      );
      await populateNamePopularity();
      break;
    case "Run All":
      console.log("\n→ Running all name setup tasks...");
      await createNameTable();
      await seedNameTables();
      await populateNamePopularity();
      break;
    case "Back to main menu":
      return;
  }
}

main();
