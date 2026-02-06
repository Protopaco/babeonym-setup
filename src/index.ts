import inquirer from "inquirer";
import importLargeSQL from "./utils/importLargeSQL";
import path from "path";
import runSQL from "./utils/runSQL";
import getFileNamesInFolder from "./utils/getFileNamesInFolder";
import seedNameTables from "./utils/Name/seedNameTables";
import populateNamePopularity from "./utils/Name/populateNamePopularity";

const postgreBasePath = path.join(__dirname, "database", "postGres");
const postgreFiles = getFileNamesInFolder(postgreBasePath);

const basePath =
  "/Volumes/Babeonym/Babeonym/babeonym-setup/src/database/data/wikipedia/";
const wikipediaFiles = [
  { name: "Create Query Tables", fileName: "wikipedia_schema.sql" },
  { name: "Seed All Titles Table", fileName: "enwiki-latest-all-titles.sql" },
  { name: "Seed Categories Table", fileName: "enwiki-latest-category.sql" },
  {
    name: "Seed Category Links Table",
    fileName: "enwiki-latest-categorylinks.sql",
  },
  { name: "Seed Page Props Table", fileName: "enwiki-latest-page_props.sql" },
  { name: "Seed Redirect Table", fileName: "enwiki-latest-redirect.sql" },
  { name: "Seed Page Links Table", fileName: "enwiki-latest-pagelinks.sql" },
  { name: "Seed Pages Table", fileName: "enwiki-latest-pages-articles.sql" },
];

console.log("Welcome to the Babeonym Setup!\n");
const main = async () => {
  let exit = false;

  while (!exit) {
    const { mainChoice } = await inquirer.prompt([
      {
        type: "select",
        name: "mainChoice",
        message: "What would you like to do?",
        choices: ["Names", "Exit"],
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
        message: "Wikipedia Categories - Select action:",
        choices: wikipediaFiles.map((file) => file.name),
      },
    ]);

    const choice = wikipediaFiles.find((file) => file.name === action);
    if (choice) {
      await importLargeSQL(basePath + choice.fileName);
    } else {
      console.log("Invalid choice");
    }
  }
};

async function wikipediaArticlesMenu() {
  const { action } = await inquirer.prompt([
    {
      type: "select",
      name: "action",
      message: "Wikipedia Articles - Select action:",
      choices: [
        "Generate article tables",
        "Seed article data",
        "Back to main menu",
      ],
    },
  ]);

  switch (action) {
    case "Generate article tables":
      console.log("\n→ Generating article tables...");
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
        "Run One",
        "Run All",
        "Seed Name Tables",
        "Populate Name Popularity",
        "Spin Up Database",
        "Back to main menu",
      ],
    },
  ]);

  switch (action) {
    case "Run One":
      const { fileToRun } = await inquirer.prompt([
        {
          type: "select",
          name: "fileToRun",
          message: "Select SQL file to run:",
          choices: postgreFiles,
        },
      ]);
      console.log(`\n→ Running ${fileToRun}...`);
      await runSQL(`${postgreBasePath}/${fileToRun}`);
      break;
    case "Run All":
      console.log("\n→ Running all name setup tasks...");
      for (const fileName of postgreFiles) {
        console.log(`\n→ Running ${fileName}...`);
        await runSQL(`${postgreBasePath}/${fileName}`);
      }
      break;
    case "Seed Name Tables":
      console.log("\n→ Seeding name tables...");
      await seedNameTables();
      break;
    case "Populate Name Popularity":
      console.log("\n→ Populating name popularity...");
      await populateNamePopularity();
      break;
    case "Spin Up Database":
      console.log("\n→ Spinning up database...");
      for (const fileName of postgreFiles) {
        console.log(`\n→ Running ${fileName}...`);
        await runSQL(`${postgreBasePath}/${fileName}`);
      }
      await seedNameTables();
      await populateNamePopularity();
      break;
    case "Back to main menu":
      return;
    default:
      console.log(`\n→ Running ${action}...`);
      await runSQL(`${postgreBasePath}/${action}`);
      break;
  }
}

main();
