---
name: curate-meanings
description: Use when turning Babeonym's raw meaning rows into display-ready curated meanings — condensing restatements, fixing capitalisation, dropping junk, and writing curated CSV batches. Use for any batch of the curation pass, and whenever a new source adds meanings that need the same treatment.
---

# Curating meanings

The rules produced `normalised_meaning_candidates` and the tables published from
it. They are honest but blunt: Edward publishes as five rows reading "rich",
"riches", "wealth", "guard", "ward", everything is lowercased, and some rows are
fragments of an etymology rather than a meaning. This pass fixes that by reading
the raw rows for a name and writing what a person should see.

It is a judgment pass, so it is not deterministic. Everything it produces is
committed as CSV, which is the only record of it.

## The hard rules

**Never invent a meaning.** Every curated line must be recoverable from the raw
rows for that name. If the rows say "horse" and "friend", the curated text may
say "Horse" and "Friend" — it may not say "Lover of horses" unless a row says
so. Inventing the connective between two fragments is inventing a meaning.

**Empty beats plausible.** If every row for a name is junk, curate it to empty
rather than reaching for something that sounds right. A blank name page is
honest; a confident wrong meaning is not, and nobody will ever catch it.

**Cite the source phrases.** Every curated row carries the raw phrases it was
condensed from, written out rather than referenced, so a spot check is a read
rather than a judgment and needs no database. A curated row that cites nothing
is a bug, and the loader refuses a batch citing a phrase the name has no raw row
for.

Row ids are deliberately not used: `normalised_meaning_candidates` is truncated
and renumbered from 1 on every normalise run, so an id cited here would point at
an unrelated meaning within a run or two.

**Never touch the raw.** `normalised_meaning_candidates` is rebuilt from claims
by the normaliser and is authoritative. This pass only adds.

## What to write

### Capitalisation

Sentence case, with proper nouns capitalised: `Wealth`, `Who is like God?`,
`Hindu god of the wind`, `Thor's stone`.

The deity rule, settled deliberately:

- **`God` takes a capital when it names the specific deity** — the Hebrew, Greek
  and Arabic theophoric names. "God is gracious", "Gift of God", "My God is an
  oath". It is a proper noun there, the same as Yahweh or Allah.
- **`god` stays lowercase when it is a common noun** — "God of war", no:
  `Roman god of war`, `A god`, `The sun-god`, `Hindu god of the wind`. The
  deity's name is the proper noun; "god" is the description.
- **Named deities are always capitalised** — Vayu, Shiva, Janus, Mars, Thor,
  Min, Yahweh.

Writing `shiva` or `vayu` lowercase is as wrong as writing `god` where the
source meant the Abrahamic deity. Both are proper nouns and both get capitals.

### Condensing

Work **per language**. Within one language, collapse restatements of one sense
into a single curated row; across languages, never merge.

- Edward's English rows "rich", "riches", "wealth" are one sense → `Wealth`.
  "guard" and "ward" are a second → `Guard`. Two curated rows, both English.
- Sophia's "wisdom" (Greek), "wisdom" (Greek) and "wisdom" (untagged) are one
  row → `Wisdom`, Greek.

**A tagged row beats an untagged duplicate.** When the same sense appears with
and without a language, keep the language.

**There is no cap.** A name with six genuinely distinct senses keeps all six —
that is a name with a rich history, not clutter. Limits on how many to show
belong to the API and the frontend, not here. In practice the dedupe does the
work: 72% of names have one or two meanings before curation.

### What to drop

- Fragments and broken merges from the old scrape: `rain)`, `mil ( gracious`,
  `god is gracious present`, `love of god friend of god`.
- Anything that is a name rather than a meaning, if the rules missed it:
  `Catherine` as the meaning of Kadi.
- Glosses of a different entry on the same page — a surname's meaning on a given
  name, if it reads as one: Becker as "baker".
- Text that states a part of speech rather than a meaning.

Dropping every row for a name is a valid outcome. Write the name with empty
text so the publish step knows the name was curated to nothing and does not fall
back to the raw rows.

## Input

Run this for the next batch, adjusting the offset. Names come in popularity
order, because that is where the looking happens.

```sql
WITH ranked AS (
  SELECT gn.id, gn.given_name,
         ROW_NUMBER() OVER (ORDER BY SUM(p.total_occurrences) DESC NULLS LAST, gn.given_name) AS rank
  FROM given_names gn
  LEFT JOIN given_name_popularity_by_decade p ON p.given_name_id = gn.id
  GROUP BY gn.id, gn.given_name
)
SELECT ranked.rank, ranked.given_name, c.text,
       COALESCE(l.label, '') AS language, c.confidence, c.source
FROM ranked
JOIN normalised_meaning_candidates c ON c.given_name_id = ranked.id
LEFT JOIN languages l ON l.id = c.language_id
WHERE ranked.rank > :batch_start AND ranked.rank <= :batch_end
ORDER BY ranked.rank, l.label NULLS LAST, c.confidence DESC;
```

About 150 names per batch. Read every row for a name before writing its curated
rows — the sense you need is often in the row with the lowest confidence.

## Output

One CSV per batch at `src/database/data/curated/meanings-batch-NNN.csv`,
committed. Continue from the highest batch number already present.

```csv
given_name,text,language,source_phrases,note
Edward,Wealth,English,rich|riches|wealth,
Edward,Guard,English,guard|ward,
Sophia,Wisdom,Greek,wisdom,
Michael,Who is like God?,Hebrew,who is like god?,
Kadi,,,catherine,the only gloss is another name
```

- `text` empty means curated to nothing, and suppresses the raw fallback.
- `language` empty is allowed when no row for that sense carries one.
- `source_phrases` are the raw phrases this line condenses, copied exactly as
  the raw rows spell them and separated by `|`. Always at least one, including
  on a row curated to nothing. They are matched case-insensitively, so the
  lowercase the normaliser produces is fine to paste.
- `note` is for anything a later reader would otherwise have to re-derive: why a
  name went empty, or why a sense was kept despite looking odd.

Then load and publish:

```bash
npm run pipeline -- meanings:load-curated
npm run pipeline -- meanings:publish
```

`meanings:load-curated` reads every batch file, resolves each line, and writes
nothing unless all of them resolve — so a batch with three bad lines is
corrected in one pass rather than over three runs. It replaces what it loaded
before, which means a corrected CSV is just re-run.

`meanings:publish` then prefers curated rows over raw rows for the same name,
and falls back to raw for names not yet curated. Partial curation is a normal
state, not a half-finished migration. Curated rows ignore the 0.5 confidence
floor the raw rows are held to: a person read the row, which outranks the number
it inherited.

## Worked examples

| Raw rows | Curated | Why |
| --- | --- | --- |
| rich, riches, wealth, guard, ward (English) | `Wealth` (English), `Guard` (English) | One sense each, restatements dropped |
| wisdom (Greek), wisdom (Greek), wisdom (untagged) | `Wisdom` (Greek) | Same sense; the tagged row wins |
| who is like god? (Hebrew) | `Who is like God?` (Hebrew) | The specific deity, so a capital |
| hindu god of the wind (Sanskrit) | `Hindu god of the wind` (Sanskrit) | Common noun; Vayu is the proper noun, not "god" |
| descendant of, descendant of , ('s, 's follower) | *(empty)* | Points at another name, and is broken text |
| horse (Greek), friend (Greek) | `Horse` (Greek), `Friend` (Greek) | Components. "Lover of horses" would be invention |

## Verifying a batch

The loader already refuses a batch that cites a phrase the name has no raw row
for, so invention is caught before anything is written. What is left is
judgment: read twenty curated lines beside the phrases they cite — straight from
the CSV, no query needed — and confirm each condenses the source rather than
rewriting it.

Re-check after the normaliser's rules change, since a phrase a batch cites may
no longer be produced:

```sql
SELECT gn.given_name, curated.text, curated.source_phrases
FROM curated_meanings curated
JOIN given_names gn ON gn.id = curated.given_name_id
WHERE EXISTS (
  SELECT 1
  FROM unnest(string_to_array(curated.source_phrases, '|')) AS cited (phrase)
  WHERE NOT EXISTS (
    SELECT 1
    FROM normalised_meaning_candidates raw
    WHERE raw.given_name_id = curated.given_name_id
      AND raw.text = cited.phrase
  )
);
```

Report how many names went empty — a batch that empties more than a few per
hundred means a rule is cutting too deep.
