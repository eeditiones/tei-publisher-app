---
name: consult-docs
description: >-
  Look up TEI Publisher reference documentation as Markdown sections. Use when you need
  details on ODDs or the processing model, HTML templating, layout/themes, REST/OpenAPI
  extension, facets, search, hosting, or pb-* web component behaviour beyond what the
  other skills cover.
---

# Consult TEI Publisher documentation

For **which files to edit** and how to extend templates without forking profiles, read
**customize-templates** first. This skill is reference lookup only.

Fetch **one section at a time** as Markdown. Do not load an entire manual. Report which section you are reading.

## How to fetch

Use the same eXist server as this app — read the URL from `.existdb.json` → `servers`
(the entry referenced by `sync.server`). Docs are served by the `tei-publisher` app on
that server.

Probe whether it is installed:

```sh
curl -sf -o /dev/null -w "%{http_code}" \
  "<server>/apps/tei-publisher/api/document/doc%2Fdocumentation.xml/md?id=intro"
```

A `200` response means you can fetch sections locally:

```text
<server>/apps/tei-publisher/api/document/doc%2F<doc>.xml/md?id=<section-id>
```

**Fallback** if the `tei-publisher` app is not installed on that server:

```text
https://www.teipublisher.com/api/document/doc%2F<doc>.xml/md?id=<section-id>
```

`<doc>` is either `documentation` (reference manual) or `webcomponents`.

## Reference manual (`documentation.xml`)

| Topic | Section id |
|---|---|
| Introduction / Jinks overview | `intro` |
| Data layout and packages | `data-organization` |
| Development workflow | `development-workflow` |
| TEI Processing Model (ODDs) | `odd` |
| Processing model syntax | `pm-syntax` |
| Models, behaviours, renditions | `pm-models` |
| Anatomy of a Jinks profile | `anatomy` |
| HTML templating | `templates` |
| Templating syntax | `templates-syntax` |
| Layout, themes, styling | `themes-and-styling` |
| Custom CSS | `themes-and-styling-custom-css` |
| Page layout areas | `layout` |
| Supported input formats | `supported-input-formats` |
| DOCX conversion | `docx` |
| Server-side API | `api` |
| Custom API endpoints | `api-custom-endpoints` |
| URL routing | `url-routing` |
| Internationalization | `i18n` |
| Search and indexing | `search` |
| Facet configuration | `facets` |
| Hosting / production | `production` |

## Web components (`webcomponents.xml`)

How `pb-*` components work together in templates. For per-component attributes and events,
see the [pb-components API](https://cdn.tei-publisher.com/) instead.

| Topic | Section id |
|---|---|
| Overview | `webcomponents` |
| Component communication | `webcomponents-communication` |
| Facsimiles / IIIF | `facsimiles` |
| Loading (CDN vs local) | `web-components-loading` |
| Custom components | `custom-components` |
| Embedding Publisher elsewhere | `embedding` |
