import { query } from "./wikipool";

export type PageRawData = {
  id: number;
  pageid: number;
  infoboxJson: object;
  sectionsJson: object;
  categories: string[];
  text: string;
  wtfJson: object;
  dateCreated: Date;
  dateUpdated: Date;
};

export default async (page_id: number): Promise<PageRawData | null> => {
  const { rows } = await query("SELECT * from get_page_raw_data($1)", [
    page_id,
  ]);
  if (rows.length === 0) {
    console.log(`No raw data found for page_id: ${page_id}`);
    return null;
  }
  const {
    out_id: id,
    out_pageid: pageid,
    out_infobox_json: infoboxJson,
    out_sections_json: sectionsJson,
    out_categories: categories,
    out_text: text,
    out_wtf_json: wtfJson,
    out_date_created: dateCreated,
    out_date_updated: dateUpdated,
  } = rows[0];
  return {
    id,
    pageid,
    infoboxJson,
    sectionsJson,
    categories,
    text,
    wtfJson,
    dateCreated,
    dateUpdated,
  };
};
