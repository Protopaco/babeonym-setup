/**
 * Names come from the SSA data and are plain ASCII in practice, but a stray
 * quote or backslash reaching a SPARQL literal would break the whole batch
 * rather than one name.
 */
export default (value: string) => {
  return value
    .replace(/\\/g, "\\\\")
    .replace(/"/g, '\\"')
    .replace(/\n/g, "\\n")
    .replace(/\r/g, "\\r")
    .replace(/\t/g, "\\t");
};
