---
name: style-app
description: >-
  Restyle or theme this Jinks-generated TEI Publisher app: colours, fonts, logo, splash
  and background images, the menubar/toolbar/sidebar look, named-entity and paragraph
  styling in the reading pane, or adding a custom stylesheet. Explains which of the three
  CSS cascades a change belongs to and how to make it take effect. Use whenever the user
  wants the app to look different.
---

# Style the app

Try `config.json` first — most theming is a config key, not CSS. Read the schema before
editing it (`<jinks-server>/schema/jinks.json`, default
`http://localhost:8080/exist/apps/jinks/schema/jinks.json`) and look under `theme`.

Never edit the CSS files Jinks generated (`resources/css/base.css`, `jinks-theme.css`,
`jinks-variables.css`, `jinks-components.css`, `pico-*.css`, `layouts.css`, `menu.css`,
anything under `transform/`, and the page layouts under `templates/layouts/`). Override
their custom properties or add your own file instead — otherwise every regeneration
reports a conflict and your work fights the upstream profile.

## 1. Pick the right cascade

Styling splits into three independent cascades. Decide what you are styling first,
because a rule in the wrong file simply has no effect.

| What you want to change | Cascade | Where it belongs | How it takes effect |
|---|---|---|---|
| Anything **inside the reading pane**: transcription text, named entities (`.persName`, `.placeName`), paragraphs, headings, footnotes, register lists | `pb-view` shadow DOM, styled only by the ODD's rendition CSS | `resources/odd/<name>.css` — the file named in the ODD's `<rendition source="…"/>` | upload it, then `jinks run <abbrev> fix-odds` (see **manage-odds**) |
| The **chrome around** the reading pane: menubar `.page-header`, `.logo`, breadcrumb `.toolbar`, side panels `aside.before`/`aside.after`, `main`, page background | light DOM, document-level stylesheet | your own `resources/css/<name>-custom.css`, registered in the `styles` array of `config.json` | upload the CSS and it is live; regenerate only when the `styles[]` entry is new |
| Web component **shadow internals** you cannot reach from the light DOM (`:host(pb-search)`, `:host(pb-login)`, `:host(pb-lang)` …) | component shadow DOM, fed by the assembled `components.css` | a separate sheet registered as `theme.components.styles` | upload, register, then regenerate so the generator re-assembles `components.css` |

The reading-pane row above names *where* rendition CSS lives, not license to hand-edit
whatever file is there. If the ODD is upstream (check `.jinks.json` for a tracked hash),
derive your own instead — see **manage-odds** § "Deriving from another ODD" — and scope
it to the affected documents rather than replacing `defaults.odd` app-wide.

For component-shadow overrides, do not copy or fork `jinks-components.css` — it belongs
to the `theme-base10` profile and your copy would drift from upstream. Add a small sheet
(e.g. `resources/css/<name>-components.css`) holding only your `:host(...)` deltas and
point `theme.components.styles` at it. The generator concatenates it **after**
`jinks-components.css`, so same-specificity rules of yours win by cascade order.
Re-declare only the properties you actually want to change.

The fact that ties the three together: **CSS custom properties inherit across shadow
boundaries.** Setting a variable on `:root` in your light-DOM custom CSS (for example
`--pb-view-max-width`, `--jinks-content-font-family`, `--jinks-colors-500`) reaches into
both the component shadows and the `pb-view` shadow. Overriding `--jinks-*` and `--pb-*`
variables from your own file is the cleanest way to retheme, and it never touches a
Jinks-owned file.

## 2. What `config.json` already gives you

Under `theme`:

- `colors.palette` — one of the shipped palettes (`neutral`, `dark`, `blue`, `green`,
  `beige`, `teal`). This is the single highest-impact change.
- `fonts.{base,content,heading}.{family,size,weight,line-height}` — note this only
  *names* a family. To actually render a web font you must also **load** it: put an
  `@import` or `@font-face` in your `styles[]` custom CSS, keeping `@import` as the first
  rule in the file. Being document-level it reaches the reading pane's shadow DOM.
  Self-host the `.woff2` if you want no external dependency.
- `logo.{image,width,height}` and `splash.{image,width,height}` — the image path is
  relative to `resources/css`, so a file in `resources/images` is `../images/foo.svg`.
  Prefer a square-ish width/height to avoid stretching. An SVG used as a logo cannot load
  web fonts, so author any lettering as outlined `<path>`, not `<text>`. These paths point
  at plain files Jinks doesn't generate — regenerating won't put them on the server, so
  also `xst upload <file> /db/apps/<abbrev>/resources/images`.
- `menubar.{background-color,background-image,color}` and
  `toolbar.{background-color,color}` — the toolbar exposes no image, so a background
  image on that bar has to come from your custom CSS targeting `.toolbar`.
- `body.{background-color,classes}`, `content.max-width`, `breadcrumbs.max`,
  `texture.background-image`, and `layout.*` for the panel widths and collapse behaviour.

Arrays in `config.json` — `styles`, `script.custom`, `odds` — are **merged** with what the
profiles contribute rather than replacing it. List only your own entries; the profile's
stay. Check `context.json` after regenerating to see the result of the merge.

## 3. Deploy and verify

- **`config.json` changed** → `jinks update -c config.json --sync` (see
  **update-app-on-server**).
- **A custom file that Jinks does not generate** (your `*-custom.css`, an SVG, a font, a
  `script.custom` file) → `xst upload --config .existdb.json <local-file>
  /db/apps/<abbrev>/resources/css` and it is live immediately, no regeneration needed. The
  target must be a **collection**, not a file path. Or run `jinks watch` for a
  save-to-server loop.
- **ODD changed** → see **manage-odds**: upload the ODD, then run `fix-odds`.
- **Verify with a cache-bypassing reload.** The `?v=` on the stylesheet link is fixed per
  page load, so a stale sheet survives an ordinary refresh — repeating the refresh will not
  help. Hard-refresh before concluding a rule did not work.
- **Check the reading pane through its shadow root.** Rules there live in a shadow DOM, so
  a document-level query or an ordinary devtools inspection misses them, and "it did not
  work" is ambiguous between your CSS, the compile and the cache. One expression settles
  it: `document.querySelector('pb-view').shadowRoot` exposes the single `<link>` to
  `transform/<odd>.css` plus the rendered content, so you can read `getComputedStyle` on a
  real node and see the values that actually applied.

## Golden rules

1. Try `config.json` → `theme` first, and read the schema before editing.
2. Never edit a Jinks-owned CSS file — override its custom properties or add your own.
3. Reading pane = ODD CSS + `fix-odds`; chrome = a `styles[]` custom sheet; component
   internals = `theme.components.styles`.
4. Name a font in `theme.fonts`, but load it in your own document-level CSS.
5. Drive anything that appears on both a dark and a light background from an inherited
   custom property with a sensible default, rather than hardcoding one of the two.
6. Verify with a hard refresh, and read the reading pane's real values through
   `document.querySelector('pb-view').shadowRoot` rather than assuming.
