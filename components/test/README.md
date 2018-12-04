# Testing Web Components

## Setup

```
npm install
```

Further information on [WCT](https://github.com/Polymer/tools/tree/master/packages/web-component-tester).

## Running the Test

To use a non standard Chrome binary use the `WDIO_CHROME_BINARY` shell  variable:

```shell
export WDIO_CHROME_BINARY="/usr/bin/google-chrome-beta"
```

Run wct test:

```shell
npm test
```

or manually:

```shell
./node_modules/.bin/wdio wdio.conf.js --spec specs/wct-index.spec.js
```

## Continuous Integration with Jenkins

Every push into the master branch on Gitlab will trigger [a CI job in Jenkins](https://jenkins.existsolutions.com/view/Tei-Publisher/job/teipublisher-web-components-test/).

Setup intructions can be found in the [jenkinsci/gitlab-plugin repo's wiki](https://github.com/jenkinsci/gitlab-plugin/wiki/Setup-Example).
