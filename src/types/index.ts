export interface NameData {
  name: string;
  gender?: string;
  origin?: string;
  meaning?: string;
  popularity?: number;
  variants?: string[];
}

export interface WikiCategory {
  id: number;
  title: string;
  parent?: string;
}

export interface WikiNameDefinition {
  name: string;
  content: string;
  categories: string[];
  infobox?: Record<string, string>;
}

export interface ProcessedName extends NameData {
  sources: string[];
  confidence: number;
  lastUpdated: Date;
}
