# Contributing Guide

First of all, if you are thinking about contributing to this component, thanks a lot! We will try to help you as much as
we can. With your help we will make this component better :) You can contribute in many ways: filling issues (with
bugs or improvements), investigating current ones and providing more information or just making Pull Requests with
fixes/new features.

Please, read this file before contributing to this component. Thanks.

## Submitting Pull Requests

When making a pull request, please make sure you take a look to the following list and do all the tasks:
1. Write (or modify) a test for the change. If there was a bug that was not covered by one of the existing unit test, 
make sure the test fails before introducing your change.
1. Make sure that all test are green (apart from the two mentioned in the `README.md` file).
1. Run `npm run lint` and make sure there are no errors.
1. Update `CHANGELOG.md` file describing the change you just made. There is no need to fill the version or the date.

For example:

```markdown
## Release X.X.X (XXXX-XX-XX)

### Bug Fixes
- Fixed a typo in the code that was causing an error when calling `hideSuggestions()` method.
```

