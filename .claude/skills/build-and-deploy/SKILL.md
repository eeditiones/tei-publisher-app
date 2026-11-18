---
name: build-and-deploy
description: >-
  Package this app as a `.xar` archive and install it on an eXist-db server. Use for
  releases, for handing the app to someone else, or for deploying to a server that has no
  Jinks installed. Not the loop for day-to-day changes — that is `jinks update`.
---

# Build a release and deploy it

This is the **release path**: it packages the whole application into a single `.xar` and
installs that archive. It coexists with the development loop but serves a different
purpose:

- Day-to-day changes → `jinks update -c config.json --sync` or `jinks watch`
  (see **update-app-on-server**). The server regenerates in place.
- A release, a hand-off, or a target server without Jinks → build a `.xar` as below.

When installing a release, deploy the **whole archive**. Do not push individual files
into the target as a substitute — that leaves the installed app inconsistent with
`expath-pkg.xml` and with what the build produced.

## Preconditions

- The target eXist server is reachable. `.existdb.json` → `servers` holds the URL and
  credentials `xst` uses.
- Either `ant` (with a JDK) or Node.js, for the two equivalent build paths below.

## Build

Check `config.json` → `script.webcomponents` first: `"local"` means the web components are
self-hosted and have to be fetched with npm before packaging, otherwise they are loaded
from a CDN at runtime.

With Ant:

```sh
ant                # CDN web components
ant xar-local      # self-hosted web components (runs npm install for you)
```

With Node.js, if you would rather not install Java and Ant:

```sh
npm install
npm run build              # equivalent to ant
npm run build:local        # equivalent to ant xar-local
npm run build:release      # stamps the git revision into the package
```

Either way the `.xar` lands in `build/`. CI and the Docker image use Ant by default.

## Deploy

```sh
xst package install --force build/<name>.xar
```

Use the newest `.xar` in `build/` — check with `ls -t build/*.xar`. `--force` replaces an
already-installed package of the same name. Pass `-s/--server`, `-u`, `-p` when the target
is not the server configured in `.existdb.json`.

Installing the archive re-runs the app's `post-install.xql`, which rebuilds the indexes
and the compiled ODD transforms.

## After deploying

- Open the app and confirm the version shown matches `expath-pkg.xml`.
- Open a document view. A `tmpl:error-dynamic` or `XPTY0004` there usually means an ODD
  was not compiled — see **manage-odds**.
- On a server that also has Jinks installed, a later `jinks update` still works against
  the installed app; the two mechanisms write to the same collection.
