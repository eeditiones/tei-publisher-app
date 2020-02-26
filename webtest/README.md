# Running the web test suite

## Installation

Inside the webtest directory call

```shell
npm install
```

## Run

Run the the entire test suite:

```shell
node_modules/.bin/wdio wdio.conf.js
```
or 

```shell
npm run-script test
```

or run single test specs, e.g. test `pages.js:

```shell
node_modules/.bin/wdio wdio.conf.js --spec tests/specs/pages.spec.js
```
