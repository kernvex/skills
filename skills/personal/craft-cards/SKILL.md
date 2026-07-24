---
name: craft-cards
description: Turn a drill transcript or an add-language manifest into properly-formatted Lingo flashcard Drafts in the vault's _review/ area.
disable-model-invocation: true
---

# craft-cards

Turn captured knowledge into **Draft** cards in `<Language>/_review/` for the Lingo
vault. You supply the model-drafted field values; the deterministic `lingo draft`
command renders and writes them. You never write a live card, never touch
scheduling, never promote — the user promotes a Draft by moving it out of `_review/`.

**Setup (tied to my machine):**

- Generator repo: `~/Documents/Projects/setup/esetup/obsidian-lingo` (run `lingo`
  commands here; `bun install` once).
- Vault: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Lingo`.
- Read `docs/CONTEXT.md` (glossary) and `docs/adr/0004`–`0006` in the generator repo
  before drafting; match the card contract below exactly.

## The card contract (a Word Draft)

```
---
language: German
pos: noun
gender: n
article: das
lemma: Haus
pronunciation: /haʊ̯s/
level: A1
concept: "[[house]]"
tags:
  - flashcards/german
  - theme/home
---

das Haus:::the house

> [!example]- Sentence
> Das Haus ist groß. — The house is big.
```

- `word:::gloss` is **reversible** (both directions). The word is the target
  expression *with its article* (`das Haus`) and is the note filename.
- Grammar fields stay blank for words that lack them (an interjection like `merci`
  has empty `gender`/`article`).
- `concept: "[[Title]]"` links the Concept hub. Reuse an existing Concept; only
  invent one when none exists (then draft it too).
- `pronunciation` is IPA. `level` is CEFR (default the config's first, A1).
- `theme/<x>` must be one of the themes in `lingo.yaml`, or omit it.

## You emit a payload; `lingo draft` writes it

Never hand-write notes into the vault. Build a JSON payload and run the command —
it guarantees the format and refuses to overwrite anything (unless `--force`). The
**Concept is the dedup key** everywhere, so a card is skipped when that Concept
already has a live Word (`skipped-live`) *or* already has a Draft in `_review/` —
even under a different word title, and even from earlier in the same payload
(`skipped-drafted`). Re-running an unchanged payload reports `skipped-exists`.
Read the outcome lines: anything not `drafted` did not land.

```json
{
  "concepts": [{ "title": "hello", "definition": "A greeting." }],
  "words": [
    {
      "word": "hola", "gloss": "hello", "concept": "hello",
      "code": "spanish", "pos": "interjection",
      "lemma": "hola", "pronunciation": "/ˈo.la/", "level": "A1",
      "theme": "social", "example": "¡Hola! ¿Cómo estás? — Hi! How are you?"
    }
  ]
}
```

```bash
cd ~/Documents/Projects/setup/esetup/obsidian-lingo
bun run draft --payload /path/to/payload.json --vault "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Lingo" --dry-run   # preview
bun run draft --payload /path/to/payload.json --vault "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Lingo"             # write to _review/
```

`code` must be a language in `lingo.yaml` (run `lingo add-language` first for a new
one). `concept` must match the Concept the card links — add it to `concepts[]` if
it isn't already live in the vault.

## Relations — opposites & near-synonyms (ADR-0007)

When a Concept has a natural **opposite** or **near-synonyms** (mostly adjectives —
`big`↔`small`, `big`↔`huge`/`large`), record them so the vault can show a live
same-language hint on the Word and a typed graph edge. A Relation links two
**distinct Concepts** and is stored **once** (Sym-once) — never add the reverse on
the other Concept; the vault implies it.

- **"synonym" here means a *distinct near-synonym Concept*** (`big`↔`huge`), each with
  its own Concept and Words. Two words for the *exact same* meaning are NOT a synonym
  relation — they are just two Words on the one Concept (nothing new to do).
- **On a NEW Concept you are drafting:** put the relation right in the `concepts[]`
  payload entry — `opposite` (a single Concept title) and/or `synonyms` (a list, keep
  it to ~3):

  ```json
  { "title": "big", "definition": "Large in size.", "opposite": "small", "synonyms": ["huge", "large"] }
  ```

- **On an EXISTING (live) Concept:** don't rewrite it. Run `relate`, which appends the
  property to the live Concept (safe — Concepts carry no scheduling), dedups both
  directions, ghost-strict drafts any missing target Concept stub into
  `Concepts/_review/`, and reports which same-language Words are still missing:

  ```bash
  cd ~/Documents/Projects/setup/esetup/obsidian-lingo
  bun run relate --concept big --opposite small --synonym huge,large --lang french \
    --vault "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Lingo" --dry-run   # preview
  ```

  Outcomes: `related` (added), `already-related` (dedup no-op), `stub-drafted` /
  `stub-exists` (target Concept), `opposite-conflict` (a different opposite already
  set — it is kept, yours is rejected; pick one deliberately), `source-missing` (the
  `--concept` isn't a live Concept yet — draft it first), and `[needs-word]` lines for
  target Concepts with no Word yet in `--lang`.
- **Rel-hub-and-word (current language only):** for each `[needs-word]` target, draft
  that language's Word (e.g. `French/petit` for `small`) via the normal `concepts[]`
  /`words[]` payload + `lingo draft`, using the target Concept's cross-references. Do
  NOT draft target Words for other languages — those get filled when you next craft in
  them.
- Relations never create flashcards; they are hint/graph only.

## Mode A — from a drill transcript

Pipeline (ADR-0004): capture → save raw → **clean/validate loop** → draft.

1. **Save raw.** The user pastes the transcript from their voice-to-text app. Save
   it verbatim to `_capture/<YYYY-MM-DD>-<lang>.md` in the vault. Never draft from
   the raw transcript.
2. **Clean/validate — iterate with the user.** Produce a cleaned copy and show each
   change, because voice-to-text mangles a foreign drill. Fix: missing/wrong
   diacritics (ä ö ü ß, é è, ñ), misheard target words (map back using the drill
   language), English↔target confusion (which side is the gloss), run-on
   segmentation (one utterance split, or two merged). Flag anything uncertain and
   ask. Loop until the user says it's good.
3. **Survey the vault.** Before drafting anything, run it once and work from the
   result — never grep `Concepts/` by hand:

   ```bash
   cd ~/Documents/Projects/setup/esetup/obsidian-lingo
   bun run survey --vault "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Lingo"
   ```

   One JSON payload, read-only, listing every Concept with:
   - `key` — the dedup key. Match against this; never lowercase/trim it yourself.
   - `status` — `live`, or `draft` for a hub sitting in `Concepts/_review/` (usually
     a `relate` stub). A `draft` hub **already exists**: link it, and do NOT put it
     in `concepts[]`, or `draft` will answer `skipped-exists` and drop your definition.
   - `coveredBy` — language codes with a live Word. If your target code is listed,
     that card is already made; skip it.
   - `crossRefs` — every language's existing Word with gender/IPA/example. Use these
     to fix the sense and register, exactly as Mode B uses the Manifest's.
   - `opposite` / `synonyms` — existing Relations, so you don't re-add one.

   Read the whole Concept list before inventing anything: the hub may name the
   meaning differently than the utterance suggests (`home` vs `house`).
4. **Draft.** For each vocabulary item in the *cleaned* transcript, build a Word
   entry (translate + supply gender/article/pos/IPA/level/example). Reuse a Concept
   from the Survey; add a `concepts[]` entry only for one the Survey doesn't list at
   all. Emit the payload and run `lingo draft`.
5. Report what landed and that the user promotes by moving notes out of `_review/`.

## Mode B — from an add-language manifest

The user ran `lingo add-language <Name> [--comprehensive --from <Lang>]`, which
wrote `<Name>/_review/_manifest.json`. Draft its requests.

1. **Read the manifest.** Each `requests[]` item has `concept`, `englishGloss`,
   `definition`, `conceptExists`, and `crossRefs` (every other language's Word for
   this Concept, with gender/IPA/example). Use the cross-references to nail the
   sense and register — the `--from` anchor language is listed first.
2. **Draft each request** into `manifest.target`. Fill `manifest.fields`; default
   `level` to `manifest.levelDefault`; pick `theme` from `manifest.themes` or omit.
   When `conceptExists` is false, add a `concepts[]` entry (one-line definition).
3. **Emit the payload and run `lingo draft`** with `--vault` = the manifest's vault.
   The command re-checks dedup, so anything already covered is skipped safely.
4. Report counts and remind the user to review + move Drafts up to promote them.

## Rules

- Work in batches you can eyeball; accuracy over volume.
- Run `lingo survey` before inventing a Concept — it is the one source for what
  exists. Grepping `Concepts/` is a second, informal answer that can disagree with
  the one `draft` enforces.
- Write only into `_review/`; never edit or promote a live card.
- Leave a genuinely unknown field blank rather than guess wrong — the user fills it
  during review.
