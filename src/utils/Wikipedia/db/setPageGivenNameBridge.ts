import { query } from "./wikipool";

export default async (pageid: number, givenNameId: number): Promise<void> => {
  try {
    await query(`SELECT * FROM set_page_given_name_bridge($1, $2);`, [
      pageid,
      givenNameId,
    ]);
  } catch (err) {
    console.error(
      `Error in setPageGivenNameBridge for pageid ${pageid} and givenNameId ${givenNameId}:`,
      err,
    );
    throw err;
  }
};
