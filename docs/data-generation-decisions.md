# Data Generation — Decisions

A running record of decisions made while working out requirements for the next
round of name data generation. Companion to `data-generation-plan.md`, which
describes the shape of the pipeline; this file records what was actually
decided and why.

Started 2026-09-09.

---

## Context

`given_names` and everything derived from it — gender, popularity by decade —
comes from the SSA year-of-birth files. That data is solid. Meaning, culture
and language came from a separate Wikipedia scrape that proved painful because
of inconsistent page formatting, and was wrapped up as "good enough" so that
frontend development could proceed.

The app is now stable enough to return to this deliberately. The goal is to
fill out meaning, culture and language for as many names as possible, using a
structure that isn't tied to any single source.

---

## Posture

- **Pre-release.** No users, nothing to preserve, and changing data breaks
  nothing. That once extended to calling the existing data disposable, and the
  comparison on 2026-09-10 showed otherwise: the old Wikipedia scrape has a
  meaning for nearly twice as many names as Wiktionary's clean tier, and is the
  only source of culture at all. It is merged with the new sources rather than
  replaced by them.
- **Meaningful, not authoritative.** This is an app for choosing a baby name,
  not a linguistics reference. Name meanings are subjective and the sources are
  public, so everything is taken with a grain of salt. The bar is "enough to
  feel useful and a place to start looking."
- **Police rules, not names.** There are too many names to review individually.
  Time is invested up front in getting extraction rules right, so that less
  work is needed later. Sessions are expected to be bursty — roughly quarterly
  — which means whatever is built has to still make sense after months away.
- **Changes may reach the whole stack.** Backend changes, a regenerated OpenAPI
  client and frontend work are all acceptable if the data model is right.
  Choosing the right solution now beats avoiding blast radius.

---

## Where the workbench lives

- Workbench tables live in the **local `babeonym` database**, alongside the app
  tables. This is what makes foreign keys to `given_names` possible.
- They are **never created in production.** The workbench is needed once, not
  indefinitely, and there is no reason to pay to host it.
- Production receives only published, app-facing data.
- **Reference data moves from dev to prod; it is never regenerated in prod.**
  Pipelines, seeds and publishing run against the local database. Prod is
  then loaded by copying the app-facing tables across with their ids intact,
  so ids agree between the two and prod never re-derives anything. First done
  2026-09-13. Schema migrations are still run on each database; only the data
  is copied.

---

## Sources

- **Open sources only, for now.** Behind the Name — the one purpose-built
  option — was approached and was not interested in selling data. The paid
  market is otherwise thin.
- **Both Wiktionary and Wikidata are fetched in round one**, since fetching is
  the slow part and extraction is cheap and local. Wiktionary carries meaning
  and origin; Wikidata carries languages and name relationships. Extraction for
  either can be rewritten later without re-fetching.
- **Culture stays Wikipedia-sourced.** Revisit if a better source appears.
- **Other-language Wiktionaries are a later addition.** English Wiktionary
  coverage reflects who volunteered to write an entry, which biases against
  non-English names. Adding e.g. `lo.wiktionary.org` later is another
  `data_sources` row — the same name can hold an English and a Lao document,
  since `source_documents` is unique on `(data_source_id, source_key)`.
- **API credits deferred.** Extraction is deterministic for round one. If
  meaning turns out to be thin without a model, that's the evidence for buying
  API credits — and the stored raw documents mean a model pass costs nothing
  extra in fetching.
- **Meaning did come out thin, and rules still go first.** Wiktionary alone
  gave meaning for 2.4% of the corpus, which meets the condition above, but a
  model pass can only be judged against a baseline. So the deterministic
  normaliser runs over both sources first, and a model is aimed at what the
  rules demonstrably cannot reach: the 895 phrases dropped for length, some of
  them real meanings, and the 3,047 names whose only old meaning is Wikipedia's
  opening paragraph. Casing stays out of it — a short list of proper nouns is
  easier to audit than any model call.

---

## Fetching

- **Popularity order**, starting with a sample of 1,000 names, resumable to all
  104,819. Popularity is available from `given_name_popularity_by_decade`.
- **Store raw documents before interpreting them.** Extraction reads from
  `source_documents`, never from the network, so rules can be rewritten and
  re-run freely.
- **Track match rate, sliced by popularity band.** A flat percentage is not
  useful; the shape of the decline is.
- **A low match rate in the tail is not a reason to stop.** Names that are rare
  in US birth data can be culturally central elsewhere, and those are exactly
  the names that make the culture filter worth using.
- **Two different match measures.** Whether Wiktionary has a page at all, and
  whether that page has given-name content. The gap between them is
  diagnostic — it separates "the source doesn't cover this name" from "our
  extraction is leaving data behind."

---

## Language

- **One fact, not two.** "This name is associated with language X." No
  distinction between language of origin and language of usage — too granular
  for what the app is doing.
- **Fed by three signals:** the language section a `{{given name}}` template
  appears under, the template's `from=` value, and Wikidata's `language of work
  or name`. The Wikidata one needs no alias mapping — it already points at a
  language item.
- **Err toward inclusion.** Michael is an English name today regardless of
  where it came from a thousand years ago. Adding Michael to both English and
  Hebrew costs nothing; making English smaller would hurt.
- **Normalised through a curated alias map** onto the existing `languages`
  table. Fold historical into modern by default (Ancient Greek → Greek, Old
  English → English). Tokens that aren't languages at all are rejected, and the
  rejection is sticky or every re-run puts them back in the queue.
- **Reference lists may grow.** Neither `languages` nor `cultures` is
  authoritative; both are working vocabularies. Adding historical languages
  where they're meaningful in their own right is acceptable — `Latin` and
  `Yiddish` are already there, both using 🌍 as the flag.
- **Review starts with the weight.** Extraction over the full corpus threw up
  366 unreviewed tokens covering 3,146 claims, but the distribution is lopsided:
  21 tokens carried 2,351 of those claims and 306 carried fewer than five names
  each. The 21 were decided by hand on 2026-09-10 and the tail set aside. It was
  worked in full the next day, once thin languages were judged worth a row —
  see below.
- **Of those 21:** 11 languages added, 4 historical forms folded, 1 synonym
  mapped, 5 rejected. Added were Sanskrit, Old Norse, Walloon, Atayal, Asturian,
  Esperanto, Lun Bawang, Greenlandic, Ingrian, Tausug and Aramaic. Folded were
  Old Czech → Czech, Old High German → German, Old Irish → Irish and
  Old Galician-Portuguese → Portuguese. `Slovene` maps to the existing
  `Slovenian` row — the same language under its other English name, which the
  exact-match auto-mapper could never connect.
- **Old Norse is its own row rather than folded.** It has five modern
  descendants, so folding would mean picking one arbitrarily — the same reason
  families were rejected — and it is a label someone browsing names would
  plausibly want in its own right. Old Galician-Portuguese has two descendants
  and went to Portuguese anyway: nobody browses for it, so a separate row would
  buy a filter no one opens.
- **Rejected were `surnames` (694 names), `coinages` (286), `place names` (62),
  `Slavic languages` (33) and `Proto-Germanic` (30).** The first three are worth
  naming, because they are not errors. `{{given name|en|male|from=surnames}}`
  is Wiktionary stating something true and interesting — Bradley began as a last
  name, Jayden was invented, Chelsea is a place — filed in the slot where a
  language would go. Rejecting them means only that they are not languages. The
  claims stay in `name_claims`, so a name-origin feature can still be built on
  them without re-fetching or re-parsing anything.
- **Proto-Germanic is rejected where Old Norse is kept**, which looks
  inconsistent and isn't. Old Norse was written down and is a recognisable
  label; Proto-Germanic is a scholarly reconstruction, conventionally spelled
  with an asterisk, that no parent will ever filter by. Its 30 names are Romance
  forms of Germanic names — Roberto, Eduardo, Alberto — and the claim survives
  in the table if "Germanic origin" ever becomes a feature.
- **A real language gets a row, however few names carry it** (2026-09-11). A
  row costs nothing and gives the next source somewhere to land. A thin
  language is kept out of the filter by the cutoff, but it still shows on the
  names that carry it — Khaleesi can show Dothraki with no Dothraki filter.
  Most of the 283 languages now in the table have fewer than ten names.
- **Historical and regional forms fold into their language, as a rule.** What
  004 and 005 did case by case — Old English to English, Brazilian Portuguese to
  Portuguese — became the rule for the tail. It covers old and middle stages
  (Middle French, Koine Greek), regional varieties (Swiss German, Mexican
  Spanish) and other names for the same language (Nynorsk, Valencian,
  Moldovan). Where a token names two reference languages the base is the one
  named last: Latin American Spanish is Spanish, Welsh English is English. Where
  no base exists yet, one new row stands for all the forms: Upper and Lower
  Sorbian are Sorbian.
- **Precedents for the judgment calls.** Extinct languages with an identity of
  their own get a row: Old Norse, Yola, Illyrian, Gothic, Etruscan.
  Reconstructions do not, so every Proto- language is rejected. A language with
  several descendants keeps its own row rather than being folded into one of
  them arbitrarily: Old Norse, Frankish, Old Turkic. Invented languages from
  fiction get rows — Dothraki, High Valyrian, Sindarin — since the tag is true
  of Khaleesi, Daenerys and Galadriel. Families, countries and origin
  categories are rejected, and so are tokens naming several languages at once
  (Italian or Greek), because an alias can point at only one.
- **Wikidata items are reviewed by identifier, not by label.** The identifier
  is the table's key and does not change; labels are edited by anyone. Bangla
  maps to the existing Bengali row, which keeps its label because it is the name
  most English-speaking parents will look for. Brazilian Portuguese folds into
  Portuguese but keeps its item identifier in `name_claims`, so a Brazilian
  culture can pick those names up later.
- **Codes resolve through Wiktionary's own table.** Some entries write an
  origin as a language code and a term — `from=de:Elisabeth` — which the first
  parser stored as a language called "de:Elisabeth". The 8,965 codes in
  Wiktionary's published modules, held in `wiktionary_language_codes`, resolve
  to canonical names. Those are the same strings the alias table already holds
  decisions for, so codes need no review of their own.
- **Meanings brought their own languages** (2026-09-11). The language a gloss
  translates is often one no entry wrote in `from=` — Akkadian behind Balthazar,
  Zapotec behind Nayeli — so the origin review never saw it. 64 such names were
  reviewed on the same rules and recorded in workbench 012 and 014, with rows
  from migrations 042 and 043. Of the 64, 25 got a row of their own, 16 folded
  into a language, 9 already matched a row and 14 were rejected; the 26 rows
  added include Mari, which stands for Western Mari. The calls worth
  remembering: Venetic is an unrelated ancient language and does not fold into
  Venetian; Chinook Jargon folds into Chinook, whose only name, Sahalie, comes
  from it; Old Church Slavonic and Old East Slavic keep rows for their several
  descendants; Cumbric and Sudovian keep rows as sister languages of Welsh and
  Lithuanian rather than earlier forms of them.
- **Where it ended up (2026-09-11).** Both review queues are empty: 295
  Wiktionary tokens mapped and 70 rejected, 251 Wikidata items mapped and 21
  rejected. Once old and new are combined, 17,617 names carry a language,
  against 4,889 in the old data alone.

---

## Culture

- **Name-to-culture is name-level data and needs Wikipedia.** One language fans
  out across many cultures — José is Spanish-language but Spanish, Mexican and
  Peruvian by culture — and Wiktionary carries nothing that distinguishes them.
- **Language → culture only covers same-word cases.** Around 60 of the 118
  culture labels are also language labels (Czech, Greek, Irish, Japanese,
  Yoruba), so those come free. The rest do not.
- **The culture list has gaps.** Latin America is almost entirely absent —
  Trinidadian is the only entry in the Americas. Mexican and Peruvian don't
  exist as rows, so no amount of extraction can fill that filter until they're
  added.

---

## Meaning

- **Many-to-many between names and meanings.** A `meanings` table holding
  distinct meaning text, and a bridge to `given_names`.
- **Attribution and provenance live on the bridge**, not on the meaning. If
  "wisdom" is a shared row, it can't itself be Greek — the link to a language,
  along with the source document, extraction method and confidence, belongs to
  the pairing.
- **Meaning text is normalised before insert** — trimming, casing, trailing
  punctuation — or dedup produces near-duplicate rows rather than genuine
  sharing.
- **Origin attribution is optional.** It's a bonus when present, not something
  to design around. In practice it depends on the source: Wiktionary names the
  language for most of its meanings, and the old Wikipedia scrape never does.
- **Multiple senses are presented as one line**, composed by the UI —
  "beautiful fragrance (Japanese); who is like God (Hebrew)" — not as separate
  meaning entries per origin. So the API returns the parts, not the line: an
  array of `{ text, language }`. Composing is one line of frontend; pulling a
  composed string apart again is parsing.
- **The existing `given_name_meaning` table is left untouched through round
  one**, so the old Wikipedia data survives for comparison. Its fate is decided
  after that comparison, not before.
- **Old and new are merged, not ranked** (2026-09-10). On the top 1,000 names
  the old scrape had a meaning for 530 and Wiktionary's clean tier for 300, and
  the two barely overlap — 363 meanings in common. Merged, they cover 3,449
  names, where either source alone covers about 2,600.
- **A meaning is a short phrase.** Several senses in one string — "Girl,
  Woman", "female child, girl, maiden" — become separate phrases, and a phrase
  over 25 characters is dropped. Splitting first is what makes the limit work:
  98% of Wiktionary phrases and 79% of old ones fit afterwards, and most of what
  does not is commentary or prose rather than a long meaning.
- **One normaliser for both sources**, writing to
  `normalised_meaning_candidates` and keeping the text each phrase was cut
  from, so the rules can be audited from their own output. It straightens
  quotes, splits on commas, semicolons and "or", drops phrases that are over
  length, identical to the name or commentary ("feminine form of Michael"), and
  lowercases.
- **Lowercase first, capitals later.** Lowercasing is what lets "Jewel" and
  "jewel" dedupe, at the cost of proper nouns: "thor's stone". Restoring them is
  a later pass that reads the untouched source columns. Whether "god" takes a
  capital is deliberately left until then.
- **`meaning_long` is not a meaning.** It holds Wikipedia's opening paragraph —
  "Nikolaus is a given name. Notable people with this name include" — and 3,047
  names have only that. It is not read as meaning, which settles whether
  `meaning_short` and `meaning_long` both survive.
- **Both confidence tiers are kept, and the floor moved** (2026-09-11). The
  mention tier was held back at 0.6 while it carried the noise. Once the bleed,
  the filler and the name-pointers were dropped at normalisation, what was left
  in it read as ordinary — Matthew's "gift of the Lord", Catherine's "pure",
  Edward's "rich" — and holding the floor there left those pages blank while the
  data sat in the workbench. The floor is 0.5, so everything the normaliser
  keeps is published, and confidence rides on every row for a consumer that
  wants only the stronger tier.
- **A meaning's language comes from the derivation, not the page.** In
  `{{der|en|hbo|מִיכָאֵל|lit=who is like God?}}` the page section is English,
  but the language the meaning belongs to is the second argument, `hbo`. Where
  the code sits depends on the template: second in `der`, `bor` and `inh`, first
  in `m` and `cog`, and on the term itself in `{{ety}}` and `from=` — falling
  back to the entry's own language when an `{{ety}}` term carries none. It is
  stored on the claim as Wiktionary names it and resolved at normalisation
  through the same alias decisions as origins, so a later decision needs no
  re-extraction. Only a mapped decision sets `language_id` (2026-09-11).
- **Proto-language meanings have no language.** Vladimir's "be strong" traces
  to Proto-Indo-European, which is accurate etymology, but tagging it would need
  a row for a reconstruction the language review rejects. 597 phrases are blank
  for that reason, and the claim's evidence keeps the code if that ever changes.
- **The same phrase in two languages is two meanings.** Language is part of the
  key from claim extraction through to `normalised_meaning_candidates`, whose
  unique index treats blank languages as equal so untagged phrases still dedupe.
  Leo is "lion" in Greek, Latin and Sumerian; 77 phrases across 60 names are
  kept this way. Before, whichever template came first on the page won.
- **A meaning that points at another name is not a meaning** (2026-09-11).
  Alexander as "son of Alexander" and Carter as "son of Arthur" say nothing: the
  meaning lives in the name being pointed at. A capital after "of" is what marks
  one, so meanings built from the same words stay — Benjamin as "son of the
  right hand", Bathsheba as "daughter of an oath", Ward as "son of the poet".
  The rule runs in the normaliser, over both sources; Wikipedia lost Addison as
  "son of Adam" and Hudson as "son of Hugh" with it. A second half followed: a
  gloss that is a single capitalised word is a name too — Kadi as "Catherine",
  Sasha as "Alexander" — which is read only on Wiktionary, whose glosses are
  lowercase unless they name something, while the Wikipedia scrape is Title Case
  throughout and its "Lion" is a meaning. Together they remove 493 phrases.
  21 names were left with no meaning, Bowen and Redmond and Kermit among them,
  which is the honest result: "son of Owen" answers the question with the
  question. Resolving what Owen, Rian and Talmai mean is a later job, and the
  claims keep their evidence for it.
- **Where it ended up (2026-09-11).** 3,911 phrases across 2,064 names carry a
  language, drawn from 104 languages. The rest of the 3,449 names with a meaning
  are mostly Wikipedia meanings, which record
  no language. Six claims carry a code outside Wiktionary's language table — a
  family such as `gem`, or several languages at once such as `es,pt` — and stay
  blank.
- **Published on 2026-09-11.** 7,558 pairings across 3,449 names went into
  `meanings` and `given_name_meaning_bridge`, and the languages resolved from
  both sources were merged into the bridge the app already reads: 28,757
  pairings added, taking it from 4,889 names to 17,617 across 253 languages.
  Coverage is strongest where it matters — a meaning on 83% of the top hundred
  names and 60% of the top thousand, a language on 100% and 99%. Seventeen of
  the top hundred still have none, and some of those are the 25-character limit
  rather than a missing source: Jessica's only meaning is 27 characters long.
- **A curation pass outranks the rules, per name** (2026-09-11). The normaliser
  can drop what is clearly not a meaning, but not choose between five phrases
  that are all defensible. Batch 001 read the top 150 names by popularity and
  wrote 222 rows over 125 of them, cutting 426 raw pairings to 218. A name with
  any curated row publishes those and nothing else, since the pass read the same
  raw rows and publishing both would restore exactly what it dropped. Four names
  are curated to nothing. Every other name publishes from the raw rows as
  before, which makes partial curation an ordinary state rather than a
  half-finished migration.
- **Curated rows cite phrases, not row ids** (2026-09-11). The obvious key would
  be the `normalised_meaning_candidates` id each curated line came from, and it
  would rot within a run or two: that table is truncated and renumbered every
  time the normaliser runs, and the normaliser is still changing. Phrases
  survive it. The loader resolves each cited phrase back to the strongest
  confidence it reached for that name — the same gloss can arrive from two
  templates — and rejects the batch if a phrase has no raw row at all, which is
  the check that catches a line invented rather than curated.
- **Curated capitals wait for the capitalisation pass** (2026-09-11). The CSV is
  written properly — "God is gracious", "Christ-bearer" — because a curator
  reading a phrase writes it that way, and the judgment is worth keeping. It is
  kept in `curated_meanings` rather than published: `meanings` dedupes on exact
  text, so publishing "Bear" beside the "bear" every un-curated name already
  points at would split one shared row in two and undo what the table is for.
  168 of the 173 curated phrases already existed as a lowercase row. Publishing
  lowercases, and the 173 become ground truth for the later pass over every
  meaning at once.
- **Republished on 2026-09-11**, with batch 001 preferred where it had run:
  7,350 pairings across 3,445 names and 3,520 distinct meanings, of which 218
  pairings on 121 names are curated.

---

## Confidence

Every claim carries a confidence, set by which shape it was read from rather
than by any judgment about the name. The point is to be able to take the good
data first and leave the rest sitting in the table, instead of choosing between
publishing everything or parsing everything.

- **Language.** The section a `{{given name}}` template sits under scores 0.9 —
  the strongest signal, since it is where Wiktionary files the entry. A `from=`
  endpoint scores 0.8. A middle step in a derivation chain (`English < Hebrew`)
  scores 0.5, because it says where the name passed through, not where it came
  from.
- **Gender** scores 0.8, from the template's second positional argument.
- **Meaning splits into two tiers**, and the split matters more than the exact
  numbers. The derivation tier — `lit=` at 0.85, `t=` at 0.8, a trailing
  positional gloss at 0.75 — is meaning the source states as the meaning. The
  mention tier, a gloss on a `{{m}}` or `{{cog}}` template, scores 0.5, because
  it is a translation of a related word that may or may not be the name's sense.
- **Relationships:** `varof=` and `dimof=` 0.75, `eq=` 0.6, Wikidata's
  `short name` 0.8, `given name version for other gender` 0.85, `said to be the
  same as` 0.7.
- **Two meaning sources added later.** A gloss written inline on a `from=` term
  (`from=non:bjǫrn<t:bear>`) scores 0.8, alongside `t=`. The old Wikipedia
  meanings score a flat 0.6: the scrape recorded no confidence, and 0.6 places
  them between a stated derivation gloss and a mention gloss, which is where the
  comparison put them.

The tiering earns its keep on the first names checked. John scores
"Yahweh is gracious" at 0.8 from a derivation template and "male given name"
at 0.5 from a mention — the second is not a meaning at all, and the tier is what
separates them without anyone reading either one.

Numbers are first guesses, meant to be tuned against reports rather than
defended. Re-running extraction is minutes, so changing them is cheap.

---

## Gender

- **SSA remains the published gender.** It is per decade —
  `given_name_popularity_by_decade` carries gender, `female_share` and
  `gender_difference` — so a name that read male in the 1940s and neutral by
  the 2000s shows that drift. `U` was introduced for names used fairly evenly
  across sexes within a decade.
- **Source gender is gathered but not published.** Wiktionary's
  `{{given name|en|male}}` and Wikidata's item type are free to capture, since
  both are already being parsed. They are timeless labels reflecting how a name
  is regarded, which is a weaker basis for the filter than measured usage.
  Stored as claims so the two can be compared later.
- The instinct is to be as inclusive as possible without watering down the
  data.

---

## Table names

- `meanings` — deduplicated meaning text
- `given_name_meaning_bridge` — name to meaning, carrying the optional
  language, the source, the extraction method and the confidence. Built and
  filled on 2026-09-11; `given_name_relationship_bridge` is still a design
- `given_name_relationship_bridge` — name to name, with the relationship type
  enum. `given_name_given_name_bridge` was considered; it names what is linked
  but not why, and the relationship type is the point of the table.

---

## Derivatives and related names

Originally parked as a nice-to-have, on the assumption that connecting Myke to
Mike to Michael would mean fuzzy matching. Wikidata provides the relationships
as explicit statements, so they are now in scope.

- **Stored as directed pairs, not families.** Wikidata gives pairs; nothing in
  it names a canonical member. Constructing families would mean inventing a
  judgment the source doesn't make. Pairs are also what you would cluster from
  later if families ever become worth building.
- **One table with a relationship type enum.** `given_name_id`,
  `related_given_name_id`, `relationship_type` — one pipeline, one table, with
  the type as a label on the row rather than a second system. Adopted
  provisionally, accepting that it may not survive contact with real data.
- **Only keep a pair when both names exist in `given_names`.** Michael →
  Mikkjell is noise if nobody in the SSA data is called Mikkjell. This should
  cut the volume sharply.
- **Meaning inheritance flows along directed relationships only** — `short
  name` and `given name version for other gender`. `said to be the same as` is
  symmetric and loose (Michael's list includes Mika), so it powers "related
  names" in the UI but never meaning.
- **Single hop, never chained.** Inherit from the base name only, never from a
  name that itself inherited, or one bad link propagates outward with no way to
  trace it.
- **Recorded as inherited, not copied.** The bridge records that this meaning
  reached this name via Michael, so fixing Michael's meaning identifies
  everything downstream. This also reads better in the UI: "Mike — a short form
  of Michael, which means who is like God."
- **`different from` is not a negative signal.** It means "don't confuse these
  two Wikidata items," not "these names are unrelated." Micheal is a real
  variant spelling in the SSA data.

The name information as a whole adds depth to the app. It is not its core
value, which is the interaction with names.

---

## Filters

- **A filter is only offered if it has at least 10 names** (set 2026-09-11,
  against real distributions). An empty filter is worse than no filter. 15 was
  considered and would have dropped Georgian, Cornish, Urdu and Punjabi — Urdu
  and Punjabi low not because the names are rare but because English
  Wiktionary misses names written in their own scripts. At 10, old and new
  combined give 97 language filters.
- **The cutoff is not built yet.** `get_name_filters()` currently returns every
  language row. The order of work is building the data, then reading it, then
  displaying it, and the cutoff belongs to displaying.
- **Below the cutoff is not invisible.** A name's own details show its
  languages whatever their size, so a thin language still appears on the names
  that carry it.
- **Coverage is measured per language and per culture**, not just overall. The
  number that predicts whether the Greek filter is any good is how many names
  carry the Greek tag — not what percentage of the dataset matched something.

---

## What the sources actually contain

### Wiktionary

Sampled nine names directly from the Wiktionary API on 2026-09-09: Michael,
Sophia, Mika, Siobhan, Mateo, Myles, Dashiell, Ravi, Lakshmi.

- **`{{given name|...}}` is reliably present**, once per language section. A
  page has as many as there are languages — Michael has about ten.
- **The first two positional arguments are language code and gender**
  (`{{given name|en|male|from=Hebrew}}`). The original regex discarded both;
  the brace-matching template parser now reads them.
- **Named fields observed:** `from=`, `dimof=`, `varof=`, `eq=`, `xlit=`, `A=`,
  `usage=`.
- **There is no meaning field.** Meaning lives in the etymology, in several
  template shapes:
  - `{{der|en|hbo|מִיכָאֵל|tr=mîḵāʾēl|lit=who is like God?}}` — named `lit=`
  - `{{m|grc|σοφία||[[wisdom]]}}` — gloss in a trailing positional slot
  - `{{bor|en|sa|रवि||the sun or the sun-god.}}` — same shape
  - `{{ety|en|:bor|sa:लक्ष्मी<t:mark, sign>|...}}` — newer template, gloss in
    `<t:...>`
- **`from=` values are not all languages.** Observed: `Hebrew`,
  `Ancient Greek`, `Irish`, `Sanskrit`, `Spanish`, `Germanic languages`,
  `English < Hebrew`, `surnames`, `the Bible`.
- **Conflicts appear immediately.** Siobhan's template says `from=Irish`; a
  category line on the same page says `female given names from Hebrew`. Both
  are true at different depths.
- **Rate limiting is real.** Twelve requests fired back to back were throttled,
  with a pointer to Wikimedia's rate-limit guidance.

**What the full corpus gave (2026-09-10).** The nine-name sample above is
superseded by a complete run.

- **Batching solved the rate limit rather than backoff.** The API accepts 50
  titles per request with full wikitext for each, turning 104,819 requests into
  2,096. The throttling seen earlier was a consequence of one name per request,
  not of Wikimedia being stingy. The whole corpus fetched in eight hours paced
  deliberately, with zero batches skipped.
- **104,819 names fetched; 24,063 have a Wiktionary page** — 23%. Lower than the
  sample suggested, and not a failure: the bottom half of the SSA file is
  largely one-off spellings.
- **Of those 24,063 pages, 12,050 have given-name content** — almost exactly
  half. The other half are common nouns, surnames and foreign words that happen
  to share the spelling. This is the gap the two match measures were meant to
  expose, and it is much wider than expected.
- **45,763 claims and 3,556 relationships.** Language on 12,050 names, gender on
  11,993, and **meaning on 2,479** — 21% of the names Wiktionary covers, 2.4% of
  the corpus. Relationships split cognate 1,462, diminutive 1,101, variant 993.
- **Meaning is the thin one, and that is the finding.** Wiktionary gives
  language, gender and relationships broadly and meaning narrowly. Whether 2,479
  is enough, and what to do if not, is the open question — deferred until the
  side-by-side against the old Wikipedia data has been read.
- **The extraction fault this exposed, fixed on 2026-09-11.** Where a page's
  given-name and surname entries share one language section, the meaning was
  drawn from the wrong one. Pages filing their entries under numbered
  etymologies can be separated: a gloss is read only from the subsection holding
  the given name, or from a single un-numbered Etymology, which covers the whole
  section. That removed 254 claims across 154 names, and 81 names turned out to
  carry nothing but bleed — Henry as "son of Henry", Valerie as "the drug LSD",
  Marilyn as "any Scottish mountain taller than 3,000 feet". One real meaning
  went with them, Noel as "Christmas", which Wiktionary files under the
  holiday's etymology rather than the name's. The earlier guess of roughly 11%
  is now a measurement: 254 of 4,321 gloss claims, about 6%, were separable by
  structure. What is left shares one etymology with the entry it belongs to —
  Carter as "son of Arthur" — or sits in a Proper noun block holding both
  entries, as Alexander does.

**`from=` has a syntax of its own (2026-09-11).** Wiktionary's template
documentation defines it, and the first parser guessed.

- A source is either a language name or a language code and a term —
  `de:Ulrich` — and a term can carry inline modifiers: `non:bjǫrn<t:bear>`
  glosses it, `<tr:…>` transliterates it. A chain of derivation is written with
  ` < `, and the documentation requires the spaces; that is what tells a chain
  from a modifier.
- The first parser split on a bare `<`, so `from=la:Renātus<t:reborn>` became
  two languages, "la:Renātus" and "t:reborn>". It also cut glosses in half at
  their commas.
- Of 9,057 `from=` values, 139 use code and term and 37 use modifiers; none use
  an unspaced chain, so following the documentation lost nothing. The fix
  removed 234 junk tokens from the review queue, added 68 language tags that no
  source had carried, and recovered 26 glosses as meanings.

### Wikidata

Sampled the same names via SPARQL on 2026-09-09.

- **Disambiguation is tractable.** Filtering to items whose type is a subclass
  of "given name" (Q202444) removes the archangel, the film and the several
  hundred people. Multiple name items still remain — Michael has four — but
  they split by script: one Latin, plus separate items for Μιχαήλ, מיכאל and
  Միքայել. Adding `writing system = Latin script` resolves to one, and drops
  Mika's thirty-odd Japanese kanji spellings.
- **Languages come free** via `language of work or name`. Michael: German,
  Dutch, Danish, English, French, Czech. Sophia: Dutch, German. No parsing, no
  alias mapping — typed statements pointing at language items.
- **Relationships are explicit.** Michael carries roughly fifty `said to be the
  same as` links (Mikael, Miguel, Michel, Michał, Mihai, Mike, Mick), plus
  `short name` (Mike, Mickey, Mick, Micha, Mickie) and `given name version for
  other gender` (Michaela).
- **No meaning at all.** Not on any item sampled. Sophia has no "wisdom"
  anywhere. Meaning exists only in Wiktionary's etymology templates.
- **Coverage is wildly uneven.** Michael has around ninety statements; Siobhan
  has nine and no language. The opposite failure mode from Wiktionary, which
  had something for every name tried.

**The type-filter trap (2026-09-10).** Worth writing down, because it reads like
an optimisation, was adopted as one, and cost most of a day.

- Resolving `?item wdt:P31/wdt:P279* wd:Q202444` inside the query times out: 50
  labels returned HTTP 504 after 65 seconds. The obvious fix is to resolve the
  subclass closure once — it gives 205 concrete type QIDs — and pin them in the
  query with `VALUES ?type`. On popular names that answered in 4.6 seconds.
- **It does not generalise.** On long-tail names the same shape times out again.
  Pinning the types makes the planner enumerate every instance of each — "given
  name" alone has hundreds of thousands — instead of starting from the 50
  labels. Measured on one batch: label match alone 0.3s, label plus P31 plus
  both OPTIONALs 0.6s, the same query with `VALUES ?type` 504 after 65s.
- **The fix is to not filter types in SPARQL at all.** Return `?type` unfiltered
  and filter it in the client against the same 205 QIDs. Identical results — 21
  names, 21 items, nothing missing or extra on a batch where the old shape could
  still finish — at 0.3s against 33.7s.
- **Relationships then key on item QIDs**, not labels, since the identity pass
  has already resolved them. That skips the label match entirely and is now the
  only thing keeping the query scoped to given names.
- **The cost of getting this wrong was concrete.** At 50 names a batch the old
  shape burned three 60-second timeouts before doing useful work, giving about
  10 names a minute and a ten-day projection for the corpus. The new shape does
  50 names in about 1.2 seconds.
- **A timed-out query is too big, not throttled**, so 504 is deliberately absent
  from the generic retry list. Re-sending an identical query cannot fix it. Batch
  splitting handles it instead, and is now a safety net rather than the working
  mechanism.

**What the full corpus gave (2026-09-11).** Fetched in about three hours once
the query shape was fixed, with no batches skipped.

- **26,780 of 104,819 names matched a given-name item**, yielding 39,016 claims
  and 35,280 relationships. Cognates dominate — 35,688 across both sources, on
  9,121 names — which suits the decision that `said to be the same as` powers
  related names and never meaning.
- **The two sources overlap far less than expected.** Wiktionary put a language
  on 12,050 names and Wikidata on 11,465; together they reach 17,408, 44% more
  than Wiktionary alone.
- **Some items were created in bulk and collide with other names.** 227 Seediq
  items sit in one consecutive block, and their English labels match spellings
  in the SSA data — Sita, Abu, Miyu. The tag is kept because it is additive: it
  takes nothing from Sita's Sanskrit.
- **Both sources are thin wherever names are written in another script.** Thai
  has no names at all and Gujarati two, across both sources and the old data.
  None of the 24,063 Wiktionary pages fetched has a Thai or Gujarati section —
  most likely because English Wiktionary files those names under their own
  script, while the SSA data holds Latin spellings. This is the bias
  other-language Wiktionaries were set aside for.

The two sources are complementary rather than competing: Wiktionary for meaning
and origin, Wikidata for languages and relationships.

---

## Still open

Updated 2026-09-11, after both sources were fetched and extracted and both
language review queues were emptied.

Done since the last update: the Wikidata fetch and extraction over the full
corpus, both language reviews, the `from=` parser fix, the meaning comparison
and normaliser, the filter cutoff, the language on meanings along with the
review of the languages it surfaced, the structural half of the
derivation-meaning bleed, the rule that drops a meaning pointing at another
name, publishing both meanings and languages into the app's own tables, and the
first curation batch over the top 150 names.

What is left, roughly in order:

- **The rest of the curation pass.** Batch 001 covered the 125 most popular
  names that have raw rows; 3,324 remain, at 150 a batch, so 23 of them. The
  pass runs over every name that has a meaning, not down to a cutoff. Batches
  advance themselves: the query ranks among names that have meanings and are not
  curated yet, so there is no offset to track and a batch number is only a file
  name. Publishing lowercases curated text while coverage is partial, because
  curated capitals beside raw lowercase would split shared rows in `meanings`.
  Once every name is curated there is no raw row left to clash with, and the
  capitalisation the CSVs already carry arrives by dropping that `LOWER()` and
  republishing.
- **The rest of the derivation-meaning bleed.** The useless half went with the
  name-pointer rule. What is left is a surname's meaning written in real words
  rather than a name — Becker as "baker", Ross as "headland" — which reads as a
  meaning and cannot be told apart by pattern. Resolving the names the dropped
  phrases pointed at is the other half of the answer.
- **A model pass on what rules cannot reach**, measured against the current
  baseline: the 888 over-length phrases, the 3,047 names whose only old meaning
  is Wikipedia's opening paragraph, and the 731 names holding meaning text that
  no rule turns into a usable phrase — mostly Japanese names and prose.
- **The backend switch.** Meanings and languages are published, but nothing
  reads them yet: the app still serves `given_name_meaning` and the language
  bridge exactly as before. Pointing the routes at the new tables, and dropping
  the old table afterwards, is the next piece of work and lives in the backend
  repo. Undecided there: whether a name's line shows every language on a meaning
  or one — Kasper's "treasurer" is tagged Aramaic, Hebrew and Persian.
- **Reports 001 and 005.** 001's meaning columns predate the merge and count
  only Wiktionary claims. 005 lists 5,801 names alphabetically when its purpose
  needs a per-language summary.
- **The filter cutoff in `get_name_filters()`** — displaying, so after reading.
- **Culture.** Untouched by round one and still Wikipedia-sourced. The list is
  missing most of Latin America, a Brazilian culture (whose names are held by
  item identifier), and Bengalis in India — `Bangladeshi` is the only Bengal
  row.
- **Flags.** 193 languages carry the 🌍 placeholder, most of them added across
  037 to 043.
- **The Wikidata alias refresh** lacks the stale-row cleanup the Wiktionary one
  gained with the `from=` fix. Harmless until Wikidata extraction changes.
- **Other-language Wiktionaries**, for the native-script gap above.
