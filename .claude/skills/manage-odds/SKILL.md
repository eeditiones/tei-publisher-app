---
name: manage-odds
description: >-
  Work with the ODD files that drive how documents are transformed and displayed in this
  Jinks-generated TEI Publisher app. Use when adding or editing a `.odd`, when changing
  the rendition CSS of the reading pane, when document views break with
  `tmpl:error-dynamic` or `XPTY0004`, or whenever `jinks run <abbrev> fix-odds` is needed.
---

# Add or edit an ODD

An ODD (`resources/odd/<name>.odd`) defines how each TEI element is rendered. It is not
read at request time: it is **compiled** into XQuery and CSS under `transform/`
(`<name>-web.xql`, `<name>-print.xql`, `<name>.css`, …). Editing the `.odd` therefore has
no visible effect until you recompile.

ODDs are also the one exception to the normal edit-locally-then-sync rhythm, which is why
they break more often than anything else: `--sync` only flows **server to local**, so a
custom ODD sitting in your working copy never reaches eXist on its own.

## The loop

1. Register the ODD in `config.json` → `odds` (an array of filenames, e.g.
   `["myedition.odd"]`), and decide how documents should pick it up — see "Scoping which
   documents use it" below.
2. Upload your real ODD:

   ```sh
   xst upload --config .existdb.json myedition.odd /db/apps/<abbrev>/resources/odd
   ```
3. Regenerate so the registration takes effect: `jinks update -c config.json --sync`. If
   the ODD file does not yet exist on the server, Jinks installs a **placeholder** ODD so the
   app stays generatable.
4. Recompile and sync:

   ```sh
   jinks run <abbrev> fix-odds --sync
   ```

   Rebuilds `modules/pm-config.xql` and compiles every ODD in `resources/odd` into
   `transform/` on the server. `--sync` pulls `modules/pm-config.xql` back into the local
   repo (requires `jinks-cli` ≥ 2.5.0).

Upload before you compile: `fix-odds` compiles whatever is on the server, so compiling
before the upload bakes in the placeholder. Within the loop that is steps 3 → 4.

## Scoping which documents use it

Four places decide which ODD renders a document, checked in this order (first match
wins):

1. **`?odd=` URL query parameter** — explicit, per-request override. Handy for previewing
   an ODD against a document without touching config, never used for normal operation.
2. **The document's own `<?teipublisher odd="myedition.odd"?>` processing instruction** —
   scopes to that one file. Requires editing the content document itself, which is a
   problem when it's profile-shipped (e.g. `demo-data`'s sample files): the edit will
   conflict on every future `jinks update` since sync only flows server → local.
3. **`config.json` → `collection-config`**, keyed by collection path relative to
   `defaults.data` (e.g. `"sermons"` for `data/sermons`):
   ```json
   "collection-config": { "sermons": { "odd": "myedition.odd" } }
   ```
   Scopes to every document in that collection without touching content files at all —
   prefer this over the PI for anything beyond a one-off. It's generated into
   `modules/generated-config.xql` as a `switch ($collection)`, so it regenerates cleanly
   on every `jinks update`.
4. **`config.json` → `defaults.odd`** — the app-wide fallback when nothing more specific
   matches. Right choice only when the ODD should render virtually everything the app
   serves; changing it has no effect on documents already pinned via PI or
   `collection-config`.

## Deriving from another ODD

A custom ODD normally extends a shipped one:
`<schemaSpec start="TEI teiCorpus" ident="myedition" source="teipublisher.odd">`.

**An `elementSpec` with `mode="change"` replaces the source element's models — it does not
merge with them.** To add a case, re-declare the base models you want to keep alongside
your new one. Models are tried in document order, first matching predicate wins, so put
the most specific first.