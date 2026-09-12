const QUOTE = '"';
const FIELD_SEPARATOR = ",";

/**
 * Turns the text of a CSV file into rows of fields, header row included.
 *
 * Hand-written because nothing in the project reads CSV yet, and the only CSV
 * it has to read is the curated-meaning batches, which this project also
 * writes. A dependency would bring dialect options, encoding detection and a
 * streaming interface for a file that is five columns wide.
 *
 * Quoted fields are honoured, because a meaning can contain a comma — "Bright,
 * shining one" — and a doubled quote inside a quoted field is one quote
 * character. A file ending inside a quoted field is a truncated file, so it
 * throws rather than returning most of the data.
 */
export default (fileContents: string): string[][] => {
  const rows: string[][] = [];
  let fields: string[] = [];
  let field = "";
  let insideQuotes = false;

  const endField = () => {
    fields.push(field);
    field = "";
  };

  const endRow = () => {
    endField();

    // A blank line parses as one empty field, which is an artefact of the file
    // ending in a newline rather than a row of data.
    if (fields.length > 1 || fields[0] !== "") {
      rows.push(fields);
    }

    fields = [];
  };

  for (let index = 0; index < fileContents.length; index += 1) {
    const character = fileContents.charAt(index);

    if (insideQuotes) {
      if (character !== QUOTE) {
        field += character;
        continue;
      }

      if (fileContents.charAt(index + 1) === QUOTE) {
        field += QUOTE;
        index += 1;
        continue;
      }

      insideQuotes = false;
      continue;
    }

    if (character === QUOTE) {
      insideQuotes = true;
      continue;
    }

    if (character === FIELD_SEPARATOR) {
      endField();
      continue;
    }

    if (character === "\r") {
      continue;
    }

    if (character === "\n") {
      endRow();
      continue;
    }

    field += character;
  }

  if (insideQuotes) {
    throw new Error("The file ends inside a quoted field.");
  }

  if (field !== "" || fields.length > 0) {
    endRow();
  }

  return rows;
};
