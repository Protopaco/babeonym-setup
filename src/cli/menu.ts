import inquirer from 'inquirer';

export async function startCLI() {
  const { action } = await inquirer.prompt([
    {
      type: 'list',
      name: 'action',
      message: 'What would you like to do?',
      choices: [
        { name: '📁 Extract name information from text files', value: 'extract-names' },
        { name: '📚 Extract Wikipedia categories', value: 'extract-categories' },
        { name: '🔍 Parse Wikipedia dump for name definitions', value: 'parse-wiki-dump' },
        { name: '⚙️  Process name data (gender, popularity, origin)', value: 'process-data' },
        { name: '🗄️  Setup database schema', value: 'setup-database' },
        { name: '📊 Run full pipeline', value: 'run-all' },
        { name: '❌ Exit', value: 'exit' },
      ],
    },
  ]);

  switch (action) {
    case 'extract-names':
      console.log('🔨 Extracting names from text files...');
      // TODO: Implement name extraction
      break;
    case 'extract-categories':
      console.log('🔨 Extracting Wikipedia categories...');
      // TODO: Implement category extraction
      break;
    case 'parse-wiki-dump':
      console.log('🔨 Parsing Wikipedia dump...');
      // TODO: Implement wiki dump parsing
      break;
    case 'process-data':
      console.log('🔨 Processing name data...');
      // TODO: Implement data processing
      break;
    case 'setup-database':
      console.log('🔨 Setting up database...');
      // TODO: Implement database setup
      break;
    case 'run-all':
      console.log('🔨 Running full pipeline...');
      // TODO: Implement full pipeline
      break;
    case 'exit':
      console.log('👋 Goodbye!');
      process.exit(0);
      break;
  }

  // Show menu again after action completes
  console.log('\n');
  await startCLI();
}
