export default (argName: string, defaultValue: number, maxValue: number) => {
  const argIndex = process.argv.indexOf(argName);
  if (argIndex === -1) {
    return defaultValue;
  }

  const rawValue = process.argv[argIndex + 1];
  const parsedValue = Number.parseInt(rawValue, 10);
  if (!Number.isFinite(parsedValue) || parsedValue < 1) {
    throw new Error(`${argName} must be a positive integer`);
  }

  return Math.min(parsedValue, maxValue);
};
