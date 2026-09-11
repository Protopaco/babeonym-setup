import normaliseMeaningText from "./normaliseMeaningText";
import parseSections from "./parseSections";
import parseTemplates, { WikitextTemplate } from "./parseTemplates";
import type { ExtractedNameClaim } from "../claimTypes";

/**
 * Which positional slot holds the gloss. Derivation templates name two
 * languages ({{der|target|source|term|alt|gloss}}) so their gloss is fourth;
 * mention templates name one ({{m|lang|term|alt|gloss}}) so theirs is third.
 * Reading the wrong slot returns the alternative spelling instead — that is
 * what "Μῐχᾱήλ" is in {{der|en|grc|Μιχαήλ|Μῐχᾱήλ}}.
 */
const DERIVATION_TEMPLATES: Record<string, number> = { der: 4, bor: 4, inh: 4 };
const MENTION_TEMPLATES: Record<string, number> = { m: 3, cog: 3 };

const DERIVATION_METHOD = "wiktionary_derivation_gloss";
const MENTION_METHOD = "wiktionary_mention_gloss";

const LITERAL_FIELD_CONFIDENCE = 0.85;
const TRANSLATION_FIELD_CONFIDENCE = 0.8;
const POSITIONAL_GLOSS_CONFIDENCE = 0.75;
/**
 * Mention templates gloss the *components* of an etymology rather than the
 * name — Alexander resolves to "to defend" plus "man" — and the same slot also
 * carries surnames, bare given names and definitional filler. Kept, but marked
 * clearly enough that the derivation claims can be published without them.
 */
const MENTION_GLOSS_CONFIDENCE = 0.5;

const readGloss = (template: WikitextTemplate, positionalSlot: number) => {
  const literal = template.named.get("lit");
  if (literal) {
    return {
      rawGloss: literal,
      field: "lit",
      confidence: LITERAL_FIELD_CONFIDENCE,
    };
  }

  const translation = template.named.get("t");
  if (translation) {
    return {
      rawGloss: translation,
      field: "t",
      confidence: TRANSLATION_FIELD_CONFIDENCE,
    };
  }

  const positional = template.positional[positionalSlot];
  if (positional) {
    return {
      rawGloss: positional,
      field: `positional[${positionalSlot}]`,
      confidence: POSITIONAL_GLOSS_CONFIDENCE,
    };
  }

  return null;
};

/**
 * Meaning is never a field on {{given name}} — it lives in the etymology.
 *
 * Extraction is scoped to language sections that actually carry a given-name
 * template, or a page like Mason takes its meaning from the stonework entry.
 */
export default (wikitext: string): ExtractedNameClaim[] => {
  const languageSections = parseSections(wikitext, 2);
  const templates = parseTemplates(wikitext);

  const findSection = (startIndex: number) =>
    languageSections.find(
      (section) =>
        startIndex >= section.contentStartIndex && startIndex < section.endIndex,
    );

  const givenNameSectionTitles = new Set(
    templates
      .filter((template) => template.name === "given name")
      .map((template) => findSection(template.startIndex)?.title)
      .filter((title): title is string => Boolean(title)),
  );

  const subsections = parseSections(wikitext, 3);
  const claims: ExtractedNameClaim[] = [];
  const seenClaimKeys = new Set<string>();

  const addClaim = (claim: ExtractedNameClaim) => {
    const claimKey = [claim.claimValue, claim.extractionMethod].join("|");

    if (seenClaimKeys.has(claimKey)) {
      return;
    }

    seenClaimKeys.add(claimKey);
    claims.push(claim);
  };

  for (const template of templates) {
    const section = findSection(template.startIndex);

    if (!section || !givenNameSectionTitles.has(section.title)) {
      continue;
    }

    const subsectionTitle =
      subsections.find(
        (subsection) =>
          template.startIndex >= subsection.contentStartIndex &&
          template.startIndex < subsection.endIndex,
      )?.title ?? null;

    const buildEvidence = (field: string) => ({
      section: section.title,
      subsection: subsectionTitle,
      template: template.name,
      field,
      raw: template.raw,
    });

    // {{ety}} carries its gloss as an inline <t:...> annotation rather than an
    // argument, so it is read off the raw text.
    if (template.name === "ety") {
      for (const match of template.raw.matchAll(/<t:([^>]*)>/g)) {
        const meaningText = normaliseMeaningText(match[1]);

        if (meaningText) {
          addClaim({
            claimType: "meaning",
            claimValue: meaningText,
            extractionMethod: DERIVATION_METHOD,
            confidence: TRANSLATION_FIELD_CONFIDENCE,
            evidence: buildEvidence("ety<t:>"),
          });
        }
      }

      continue;
    }

    const isDerivation = template.name in DERIVATION_TEMPLATES;
    const positionalSlot = isDerivation
      ? DERIVATION_TEMPLATES[template.name]
      : MENTION_TEMPLATES[template.name];

    if (positionalSlot === undefined) {
      continue;
    }

    const gloss = readGloss(template, positionalSlot);

    if (!gloss) {
      continue;
    }

    const meaningText = normaliseMeaningText(gloss.rawGloss);

    if (!meaningText) {
      continue;
    }

    addClaim({
      claimType: "meaning",
      claimValue: meaningText,
      extractionMethod: isDerivation ? DERIVATION_METHOD : MENTION_METHOD,
      confidence: isDerivation ? gloss.confidence : MENTION_GLOSS_CONFIDENCE,
      evidence: buildEvidence(gloss.field),
    });
  }

  return claims;
};
