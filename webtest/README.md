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