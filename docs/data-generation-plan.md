# Babeonym Data Generation Plan

This repo currently acts as both a setup tool and a research workbench for building the Babeonym name dataset. The goal of this plan is to keep that useful workbench idea, but make the next version easier to resume, inspect, and trust.

## Goal

Build a better pipeline for generating and publishing name data:

- Given name
- Language of origin
- Culture of origin
- Meaning

The new system should avoid treating AI as an authority. AI can help extract, compare, and summarize cited evidence, but generated facts should keep provenance, confidence, and review status.

## Phase 1: Re-Orient

1. Freeze the current setup repo as the existing research bench.
2. Document the current data flow in plain English.
3. Identify which current data is useful, experimental, stale, or publishable.

## Phase 2: Define The Target Dataset

1. Confirm the final facts Babeonym needs: given name, language of origin, culture of origin, and meaning.
2. Decide which facts belong to exact spellings and which belong to name families.
3. Define fact states such as `raw`, `candidate`, `approved`, and `rejected`.

## Phase 3: Add A Workbench Layer

1. Keep the two-database idea: one workbench database and one clean app-facing dataset.
2. Add explicit workbench tables for raw source documents, extracted claims, name families, review state, and source provenance.
3. Stop writing scraper output directly into final app-facing tables.

## Phase 4: Build Source Ingestion

1. Start from the existing `given_names` table.
2. Fetch evidence from Wiktionary.
3. Fetch structured metadata from Wikidata.
4. Store raw responses before trying to interpret them.

## Phase 5: Extract Claims

1. Parse deterministic claims first, such as templates, categories, labels, aliases, and structured fields.
2. Use AI only against retrieved/cited source text.
3. Store claims with source, confidence, extraction method, and evidence.

## Phase 6: Resolve And Review

1. Auto-approve high-confidence claims when sources agree.
2. Put conflicts, weak evidence, and fuzzy matches into a review queue.
3. Track why each fact was accepted, rejected, or left unresolved.

## Phase 7: Publish

1. Generate the clean Babeonym dataset from approved claims only.
2. Populate the existing app-facing tables:
   - `given_name_language_bridge`
   - `given_name_culture_bridge`
   - `given_name_meaning`
3. Produce a validation report every run.

## Phase 8: Iterate

1. Review coverage gaps.
2. Add new sources only when they address a specific weakness.
3. Improve matching and extraction rules based on real failures.

## Name Families

Names should support a layer between exact spellings and shared identity.

Example:

```text
Name family: Miles
Spellings: Miles, Myles, Milez
```

Popularity should remain spelling-level. Meaning and origin will often be family-level, but inherited facts should be marked as inherited rather than copied blindly.

Important rule:

```text
Fuzzy matching should suggest relationships, not automatically publish facts.
```

## Suggested First Milestone

Build a non-destructive pipeline that:

1. Reads existing `given_names`.
2. Fetches Wiktionary and Wikidata evidence for a small batch.
3. Stores raw evidence and extracted claims.
4. Prints a coverage report.

This gives the project a reliable spine before adding smarter extraction, review UI, or additional data sources.

## Early Validation Report

The first validation report should include:

- Total names
- Names with any source evidence
- Names with language-of-origin claims
- Names with culture-origin claims
- Names with meaning claims
- Names assigned to name families
- Conflicting claims
- Pending review claims
- Names with no evidence found
