import { query } from "../../utils/postGresPool";

export default async (dataSourceLabel: string) => {
  const result = await query(
    `
      SELECT id
      FROM data_sources
      WHERE label = $1
      LIMIT 1
    `,
    [dataSourceLabel],
  );

  if (result.rowCount === 0) {
    throw new Error(
      `${dataSourceLabel} data source is missing. Run workbench:init first.`,
    );
  }

  return result.rows[0].id as number;
};
