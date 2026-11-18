---
name: update-app-on-server
description: >-
  Regenerate this Jinks-generated TEI Publisher app on eXist-db and sync the result back
  into the local repo, using the `jinks` CLI. Use whenever `config.json` changed, when the
  server should be brought in line with the repo, when local custom files need to reach
  eXist, or when the user asks to update, deploy, regenerate or sync the app.
---

# Update the app on the server

> **Stop:** If you are about to edit a file under `templates/` that you did not create,
> or add a `skip` entry to fix a template/XQuery error — don't. That forks an upstream
> profile file. Read `AGENTS.md` → **Before you edit any file**, then the
> **customize-templates** skill.

Jinks is a server-side generator: it expands `config.json` against the profiles this app
was composed from and writes the result into eXist-db. Nothing you change in
`config.json` takes effect until you regenerate, and nothing the generator produces
appears locally until you sync.

## Preconditions

- `jinks` CLI available — check with `jinks --version`.
- eXist + Jinks reachable. The CLI defaults to `http://localhost:8080/exist/apps/jinks`;
  if `.existdb.json` → `servers` points elsewhere, pass `-s/--server` plus `-u` and `-p`.
- The app's `abbrev` from `expath-pkg.xml` (also `pkg.abbrev` in `config.json`).

## The one command you usually want

Run from the repo root, after editing `config.json`:

```sh
jinks update -c config.json --sync
```

`-c/--config` overwrites the app's active `config.json` **on the server** with the file
you pass, then regenerates and deploys. This matters: a plain `jinks update <abbrev>`
regenerates from the config *already stored on the server* and never reads your local
file. The target app is identified by `pkg.abbrev` inside the supplied config, so no
positional `<abbrev>` is needed. `cat config.json | jinks update -c` reads it from stdin
instead.

`--sync` pulls the regenerated files back into the local directory, which keeps the repo
authoritative. Always pass it unless you have a reason not to.

## Swapping a profile in `extends`

Before replacing one profile with another of the same kind (e.g. one theme for another),
fetch the candidate's own `config.json` from `/db/apps/jinks/profiles/<name>/config.json`
and check its `depends`. A profile that `depends` on the one you're replacing is an
overlay, not a substitute — keep both in `extends`, in dependency order, rather than
swapping.

## Variants

| Situation | Command |
|---|---|
| Regenerate from the config already on the server | `jinks update <abbrev> --sync` |
| A small edit isn't picked up (last-modified check skipped it) | add `-a` |
| Full reinstall, overwriting existing files — use sparingly | add `-r` |
| A breaking profile version change prompts for confirmation | add `-y`, but only after the user acknowledged it |

All of these compose with `-c` and `--sync`.

## Getting local custom files to the server

Sync only flows server → local, so your own new files (custom CSS, JavaScript, XQuery
modules, images) have to be pushed the other way:

- `jinks watch` — start it **before** editing and every save is uploaded live. Best for
  an iterative loop.
- `xst upload <local-file> <db-collection>` — e.g.
  `xst upload resources/css/my-custom.css /db/apps/<abbrev>/resources/css`. The target
  must be a **collection**, not a file path.

ODDs are a special case with their own ordering rules — see the **manage-odds** skill.

## After the call

Read the CLI output rather than assuming success:

- **Updated resources** — after every `jinks update --sync` or `xst upload`, report
  exactly which local files were created, modified, or deleted. Present the result as a
  table even if only one file changed:

  | File | Change |
  |---|---|
  | `templates/browse.html` | modified |
  | `resources/css/theme.css` | created |
  | `context.json` | modified |

  Use `git diff --name-status` or the sync output to populate it. If no files changed,
  say so explicitly rather than omitting the table.

- **Conflicts** — Jinks tracks a hash for every file it generated. If you edited a
  generated file, the update reports a conflict and asks whether to overwrite. A conflict
  is a **warning that you forked upstream**, not confirmation your edit was correct.
  Undo the edit and move the change into `config.json` or a new custom file. Answer
  **No** only when you are **deliberately** keeping a long-term fork the user accepted
  (`printf 'n\n' | jinks update …` non-interactively). A **recurring** conflict means
  the change belongs in `config.json` or a separate custom file — **do not** add `skip`
  as a shortcut. When you genuinely must own a generated file for good (user acknowledged,
  no extension point), stop the generator writing it at all: add a regex to `skip`,
  matched against the file's path in the app (as in base10's own `^doc/.*$`), or to
  `skipSource`, matched against the source path, which is how a profile drops its copy of
  a file several profiles supply. Both are top-level arrays in `config.json`.
- **Errors** in a template or `setup.xql` name the offending source file — fix and re-run.

## Related files

`config.json` (master input), `context.json` (generated runtime context — never edit),
`.jinks.json` (Jinks-owned hashes — never edit), `.existdb.json` (server URL and
credentials), `expath-pkg.xml` (`abbrev`).
