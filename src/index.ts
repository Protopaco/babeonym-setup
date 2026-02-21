import inquirer from "inquirer";
import importLargeSQL from "./utils/importLargeSQL";
import path from "path";
import runSQL from "./utils/runSQL";
import runWikiSQL from "./utils/wikipedia/db/runWikiSQL";
import getFileNamesInFolder from "./utils/getFileNamesInFolder";
import seedNameTables from "./utils/Name/seedNameTables";
import populateNamePopularity from "./utils/Name/populateNamePopularity";
// import setWikipediaPageIdsBulk from "./utils/Wikipedia/db/setWikipediaPageIdsBulk";
import fetchCategoryMembers from "./utils/Wikipedia/fetchCategoryMembers";
import getCultureSubcategories from "./utils/wikipedia/getCultureSubcategories";
import fetchRawPages from "./utils/wikipedia/fetchRawPages";
import fetchPageWithWTF from "./utils/wikipedia/fetchPageWithWTF";
import parseRawPages from "./utils/wikipedia/parseRawPages";
import fetchSubcategories from "./utils/wikipedia/fetchSubcategories";
import pairLanguagePage from "./utils/wikipedia/pairLanguagePage";
import pairCulturePage from "./utils/wikipedia/pairCulturePage";
import pairGivenNamePage from "./utils/wikipedia/pairGivenNamePage";
import pairMeaningPage from "./utils/wikipedia/pairMeaningPage";

const postgreBasePath = path.join(__dirname, "database", "postGres");
const postgreFiles = getFileNamesInFolder(postgreBasePath);

const wikipediaBasePath = path.join(__dirname, "database", "wikipedia");
const wikipediaFiles = getFileNamesInFolder(wikipediaBasePath);

console.log("Welcome to the Babeonym Setup!\n");
const main = async () => {
  let exit = false;

  while (!exit) {
    const { mainChoice } = await inquirer.prompt([
      {
        type: "select",
        name: "mainChoice",
        message: "What would you like to do?",
        choices: ["Names", "Wikipedia", "Exit"],
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
        message: "Wikipedia - Select action:",
        choices: [
          "Run One",
          "Run All",
          "Fetch Category Members: Given Names",
          "Fetch Subcategories: Given Names By Language",
          "Fetch Raw Pages",
          "Fetch Page with WTF",
          "Parse Raw Pages",
          "Setup Page-Language Bridge",
          "Setup Page-Culture Bridge",
          "Pair Given Name with Page",
          "Pair Meaning with Page",
          "Get Culture Subcategories",
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
            choices: [...wikipediaFiles, "Exit"],
          },
        ]);
        if (fileToRun === "Exit") {
          return;
        }
        console.log(`\n→ Running ${fileToRun}...`);
        await runWikiSQL(`${wikipediaBasePath}/${fileToRun}`);
        break;
      case "Run All":
        console.log("\n→ Running all Wikipedia setup tasks...");
        for (const fileName of wikipediaFiles) {
          console.log(`\n→ Running ${fileName}...`);
          await runWikiSQL(`${wikipediaBasePath}/${fileName}`);
        }
        break;
      case "Fetch Category Members: Given Names":
        console.log("\n→ Seeding Wikipedia page IDs...");
        await fetchCategoryMembers("Given names");
        break;
      case "Fetch Subcategories: Given Names By Language":
        const { selectedFamily } = await inquirer.prompt([
          {
            type: "select",
            name: "selectedFamily",
            message: "Choose a language family:",
            choices: [
              "Germanic given names",
              "Celtic given names",
              "Slavic given names",
              "Scandinavian given names",
              "Turkic given names",
              "Iranian given names",
              "Hindu given names",
            ],
          },
        ]);

        console.log(
          `\n→ Fetching subcategories for '${selectedFamily}' category...`,
        );
        await fetchSubcategories(selectedFamily);
        break;
        break;
      case "Fetch Raw Pages":
        console.log("\n→ Seeding Wikipedia pages...");
        await fetchRawPages(25);
        break;
      case "Fetch Page with WTF":
        console.log("\n→ Fetching page with WTF...");
        await fetchPageWithWTF();
        break;
      case "Parse Raw Pages":
        console.log("\n→ Parsing raw Wikipedia pages...");
        await parseRawPages();
        break;
      case "Setup Page-Language Bridge":
        console.log("\n→ Setting up page-language bridge...");
        await pairLanguagePage();
        break;
      case "Setup Page-Culture Bridge":
        console.log("\n→ Setting up page-culture bridge...");
        await pairCulturePage();
        break;
      case "Pair Given Name with Page":
        console.log("\n→ Pairing given names with Wikipedia pages...");
        await pairGivenNamePage();
        break;
      case "Pair Meaning with Page":
        console.log("\n→ Pairing meanings with Wikipedia pages...");
        await pairMeaningPage();
        break;
      case "Get Culture Subcategories":
        console.log("\n→ Getting culture subcategories...");
        await getCultureSubcategories("Given names by culture");
        break;
      case "Back to main menu":
        return;
    }
  }
};

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
          choices: [...postgreFiles, "Exit"],
        },
      ]);
      if (fileToRun === "Exit") {
        return;
      }
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
