---
name: customize-templates
description: >-
  Customize HTML page templates and named blocks in this Jinks-generated TEI Publisher
  app without forking upstream profile files. Use when adding or editing templates under
  templates/pages/, creating *-blocks.html files, registering templating.use, extending
  sidebars (registers, metadata, IIIF), debugging tmpl:error-dynamic, or deciding between
  append ([% template %]) and overwrite ([% template! %]).
---

# Customize HTML templates

Read **AGENTS.md** → **Before you edit any file** first. Profile templates are
upstream-owned; this skill covers the **correct extension patterns**.

Never edit profile block providers (`templates/register-blocks.html`,
`templates/browse.html`, …). Never add `skip` to silence a template error — see
**update-app-on-server**.

## Extension points

| Goal | Where |
|---|---|
| New document page layout | `templates/pages/<name>.html` + `defaults.template` in `config.json` |
| Extra blocks on many pages (sidebar, scripts, …) | **new** `templates/<name>-blocks.html` + `templating.use` in `config.json` |
| Overrides for one page only | frontmatter `---json` in **your** page template |
| Chrome / sidebar styling | `styles` array → custom CSS file (see **style-app**) |
| Custom templating functions | `templating.modules` in `config.json` |

Profile block providers (e.g. `templates/register-blocks.html` from `registers`) are
**upstream**. Extend them via `templating.use` or **your** page template — never replace
or gut the profile file.

## How named blocks compose

jinks-templates **concatenates** same-named blocks: if several files each define
`[% template styles %]` (or `after`, `scripts`, …), all of them are **appended** into the
corresponding `[% block %]` placeholder. Profiles rely on this (e.g. `registers` adds an
`after` block without touching `base10` layouts).

| Intent | Mechanism |
|---|---|
| **Add** content | `[% template name %]` in **your** `*-blocks.html` or page template → appends |
| **Replace** earlier content | `[% template! name %]` in **your** file (`!` = overwrite, not append) |

Multiple same-named templates are **not** an error. If a page fails to compile, the error
names a **source file and line** — usually invalid syntax in **your** custom template or
module.

For directive syntax and inheritance, read **consult-docs** (`templates`,
`templates-syntax`) or the [jinks-templates README](https://github.com/eeditiones/jinks-templates).

## Registering a custom block file

In `config.json`:

```json
{
  "templating": {
    "use": ["templates/my-blocks.html"]
  }
}
```

In `templates/my-blocks.html` (wrapper element optional but clarifies intent):

```html
<template>
    [% template after %]
    <!-- your sidebar content; appends to profile blocks such as registers -->
    [% endtemplate %]
</template>
```

After changing `config.json`, run `jinks update -c config.json --sync`. Upload new template
files with `xst upload` or `jinks watch` — see **update-app-on-server**.

## Anti-example: missing register sidebar map

**Wrong:** Edit `templates/register-blocks.html`, add the path to
`skip`.

**Right:** Leave `templates/register-blocks.html` untouched. Add
`templates/my-blocks.html` with `[% template after %]` and register it under
`templating.use`. To suppress upstream block content on one page only, use
`[% template! after %]` in **your** page template.

## When debugging `tmpl:error-dynamic`

1. Read the error for the named source file — fix **your** file first.
2. Do **not** rewrite profile templates or strip upstream content "to get pages loading."
3. Do **not** add `skip` as a shortcut.
4. To add blocks → new `*-blocks.html` via `templating.use`.
5. To replace a block → `[% template! name %]` in **your** file.
