import inquirer from "inquirer";
import importCategoryLinksMySQL from "./utils/Wikipedia/categoryImport";
import importPagesMySQL from "./utils/Wikipedia/pagesimport";
import createNameTable from "./utils/Name/createNameTable";
import populateNamePopularity from "./utils/Name/populateNamePopularity";
import seedNameTables from "./utils/Name/seedNameTables";

async function main() {
  console.log("Welcome to the Babeonym Setup!\n");

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
}

async function wikipediaMenu() {
  const { action } = await inquirer.prompt([
    {
      type: "select",
      name: "action",
      message:
        "Wikipedia Categories - Select action:",
      choices: [
        "Seed category tables",
        "Seed pages tables",
        "Query category tables",
        "Back to main menu",
      ],
    },
  ]);

  switch (action) {
    case "Seed category tables":
      console.log(
        "\n→ Seeding category tables..."
      );
      await importCategoryLinksMySQL();
      break;
    case "Seed pages tables":
      console.log("\n→ Seeding pages tables...");
      await importPagesMySQL();
      break;
    case "Query category tables":
      console.log(
        "\n→ Querying category tables..."
      );
      // Your function will go here
      break;
    case "Back to main menu":
      return;
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
