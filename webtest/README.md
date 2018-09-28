# Running the web test suite

## Installation

### Install selenium

```shell
npm install selenium-standalone@latest -g
selenium-standalone install
```

### Install webdriverio

Inside the webtest directory call

```shell
npm install
```

## Run

Start selenium in a shell:

```shell
selenium-standalone start
```

Run the tests:

```shell
./node_modules/.bin/wdio wdio.conf.js
```

## Web Components Test

No need to run Selenium.

To use a non standard Chrime binary use the `WDIO_CHROME_BINARY` variable:

```shell
export WDIO_CHROME_BINARY=/usr/bin/google-chrome-beta
```

Run wct test:

```shell
npm test-wct
```

or manually:

```shell
./node_modules/.bin/wdio wdio.conf.js --spec test/specs/wct-index.spec.js
```
