import inquirer from "inquirer";

async function main() {
  console.log("Welcome to the Babeonym Setup!\n");

  let exit = false;

  while (!exit) {
    const { mainChoice } = await inquirer.prompt([
      {
        type: "select",
        name: "mainChoice",
        message: "What would you like to do?",
        choices: [
          "Wikipedia Categories",
          "Wikipedia Articles",
          "Names",
          "Exit",
        ],
      },
    ]);

    switch (mainChoice) {
      case "Wikipedia Categories":
        await wikipediaCategoriesMenu();
        break;
      case "Wikipedia Articles":
        await wikipediaArticlesMenu();
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

async function wikipediaCategoriesMenu() {
  const { action } = await inquirer.prompt([
    {
      type: "select",
      name: "action",
      message:
        "Wikipedia Categories - Select action:",
      choices: [
        "Generate category tables",
        "Seed category tables",
        "Query category tables",
        "Back to main menu",
      ],
    },
  ]);

  switch (action) {
    case "Generate category tables":
      console.log(
        "\n→ Generating category tables..."
      );
      // Your function will go here
      break;
    case "Seed category tables":
      console.log(
        "\n→ Seeding category tables..."
      );
      // Your function will go here
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
        "Generate name occurrences",
        "Generate name popularity",
        "Assign name gender",
        "Name popularity by decade",
        "Back to main menu",
      ],
    },
  ]);

  switch (action) {
    case "Generate name tables":
      console.log(
        "\n→ Generating name tables..."
      );
      // Your function will go here
      break;
    case "Seed name tables":
      console.log("\n→ Seeding name tables...");
      // Your function will go here
      break;
    case "Generate name occurrences":
      console.log(
        "\n→ Generating name occurrences..."
      );
      // Your function will go here
      break;
    case "Generate name popularity":
      console.log(
        "\n→ Generating name popularity..."
      );
      // Your function will go here
      break;
    case "Assign name gender":
      console.log("\n→ Assigning name gender...");
      // Your function will go here
      break;
    case "Name popularity by decade":
      console.log(
        "\n→ Calculating name popularity by decade..."
      );
      // Your function will go here
      break;
    case "Back to main menu":
      return;
  }
}

main();
