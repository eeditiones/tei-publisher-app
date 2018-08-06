# paper-autocomplete

> Autocomplete component compatible with Polymer 1.x and 2.x

[![Published on webcomponents.org](https://img.shields.io/badge/webcomponents.org-published-blue.svg)](https://www.webcomponents.org/element/ellipticaljs/paper-autocomplete)

[![Sauce Test Status](https://saucelabs.com/browser-matrix/jhuesos.svg)](https://saucelabs.com/u/jhuesos)

`paper-autocomplete` extends earlier efforts such as this 
[https://github.com/rodo1111/paper-input-autocomplete](https://github.com/rodo1111/paper-input-autocomplete) to provide 
keyboard support, remote binding and results scrolling.

# About Polymer 1.x and 2.x Compatibility
From version `3.x.x`, this component work with both Polymer 1.7+ or Polymer 2.0+ Please take a look to the 
[MIGRATION.md](./MIGRATION.md) file that contains more information.

# Installation

``` bash

bower install paper-autocomplete

```

# Usage

```html

<link rel="import" href="bower_components/paper-autocomplete/paper-autocomplete.html">

<paper-autocomplete id="my-id" label="Select" ></paper-autocomplete>

```

# Demo and Docs

http://ellipticaljs.github.io/paper-autocomplete/

**Important: The demos only work with browers which are ES2015/ES6 compatible.**. This component is compatible with older 
browsers as well, but the code need to be transpiled to ES5. `polymer build` and `polymer serve` can do that for you.
This code from this page is not transpiled.

# Want to contribute?

Check out our [Contributing guide](./CONTRIBUTING.md)! 

# For Developers

## Getting Started

Clone the repository and run:

`npm install`

## How to run the project

You just need

## How to run the project with Polymer 1.x and Polymer 2
This component runs in Polymer hybrid mode, that means it can run in a Polymer 1.x or Polymer 2.x app.
```
npm run variants
```
After running this command, it will open two different ports  in the dev browser with Polymer 1.x and Polymer 2.x

## How to run the tests

### Localy

In order to run the tests you have two option. You can either run:

```
npm run test
```

### Remote (in Saucelabs)

```
npm run test:remote
```
> You must set these two environment variables: `SAUCE_USERNAME` and `SAUCE_ACCESS_KEY` before running remote tests.


## How to *lint* the project

```
npm run lint
```
