# Changelog

This component follows *Semantic Versioning* (aka SemVer), visit (http://semver.org/) to learn more about it.

## Release 3.7.0 (2018-04-15)
### New Features
- Add Setter/getter manually invalid input. Thanks to [@herberthobregon](https://github.com/herberthobregon).
- When source changes update suggestions. Thanks to [@programmer4web](https://github.com/programmer4web).

## Release 3.6.0 (2018-02-2813)
### Bug Fixes
- Fix removed the `readOnly` attribute from the `focused` property. This was causing that the value was not being updated. Thanks to 
[@programmer4web](https://github.com/programmer4web).
### New Features
- New `selected` property has been added that exposes the current selected value. Thanks to [@programmer4web](https://github.com/programmer4web).

## Release 3.5.0 (2018-01-28)
### Bug Fixes
- Suggestion list will now work properly if text-property or value-property not set to default value. Fixes #66 and #103. Thanks to [@christianaye](https://github.com/christianaye)
### New Features
- Component now exposes `disabled` option. Fixes #96. Thanks to [@JaySunSyn](https://github.com/JaySunSyn).
- `focused` property exposed. Fixes #102. Thanks to [@programmer4web](https://github.com/programmer4web).

## Release 3.4.0 (2017-10-28)
### New Features
- Component now exposes `readOnly` option.

## Release 3.3.0 (2017-09-21)
### New Features
- Show results on focus is now disabled by default. The new feature introduced in previous version changed the default
behavior for everyone and that might not be the best solution in all cases. So for that reason, by default, suggestions
are not displayed onfocus. If you want to add that behavior again, use the following option: `show-results-on-focus`.
Sorry for that! :)
- New option `autocapitalize` has been added (thanks @ardean).

## Release 3.2.0 (2017-09-10)
### New Features
- Suggestions will be displayed (if available) on focus (thanks to @nomego)
- New CSS mixin to give custom styles to suggestions (`--suggestions-item`);
- `paper-item` slot `prefix` is also now exposed and it can be used (thanks to @nomego)

## Release 3.1.0 (2017-08-27)
### New Features
- Added a new boolean option `highlight-first` to both `paper-autocomplete` and `paper-autocomplete-suggestions` that
when set, it will always highlight the first result each time new suggestions are presented.

## Release 3.0.2 (2017-08-23)
### Bug Fixes
- It is now again possible to add a custom `paper-input` suffix. See the new demo.

## Release 3.0.1 (2017-08-12)
### Bug Fixes
- Removed duplicated `auto-validate` attribute from paper-autocomplete (thanks to @kaseyhinton).
- Fixed regression: `onClear()` now triggers `'autocomplete-reset-blur'` event (as is documented in the API) and *not*
the event `'autocomplete-reset'`.
- Added integration with SauceLabs so now test can be run against multiple platforms and browsers.

## Release 3.0.0 (2017-07-16)

### Breaking Changes
- This version does not contain any breaking change in the API. The breaking changes come from limitations in styling
when working with `<slots>` and ``::slotted()``. Due to this limitations, when working with custom templates, you must
put your `<style>` inside the custom template `<template>` tag.

### New Features
- The component has been transformed to work in *hybrid mode*, which means that the component is now compatible with
both Polymer 1.x and Polymer 2.x.

*Special thanks to everyone who has contributed to this version. Specially *@ajbarriosleon, @kamte* who did most of 
heavy-lifting at the beginning of this new version.

### Known Issues
- `tabindex="-1"` was added to the clear button, so you can no longer use tab to focus it.
This is a temporary workaround until this issue is fixed: https://github.com/PolymerElements/paper-input/issues/324 .

## Release 2.6.1 (2017-06-10)

### Bug Fixes
- Private property `_bindedFunctions` inside `paper-autocomplete-suggestions` was being shared between all 
instances. This now has been solved thanks to [@plequang](https://github.com/plequang).

## Release 2.6.0 (2017-05-31)

### New Features
- Updated `README.md` to clarify compatibility with Polymer 1.x and 2.x.

## Release 2.5.2 (2017-05-12)

### Bug Fixes
- Moved `<style>` tags inside the `<template>` tag, to avoid leaking styles and to be inline with latest Polymer
recommendations (thanks to @alejost848).
- Demo pages has been fixed so now all demos work in IE/Edge.
- Event name when clicking in the clear button was wrong. Now event name matches the one in the documentation:
`autocomplete-reset-blur` (thanks to @orenagiv).

## Release 2.5.1 (2017-03-30)

### Bug Fixes
- Removed `mocha`, `chai` and `sinon` from the list of bower dependencies.

## Release 2.5.0 (2017-03-24)

### New Features
- X button to clear is now a paper-input suffix.

### Bug Fixes
- Hiding native clear X button in the input in IE/Edge. Fixes #24 

## Release 2.4.0 (2017-02-22)

### New Features
- `paper-autocomplete` now exposes a new CSS mixin that can be used to style the suggestions popup:
`--paper-autocomplete-suggestions-wrapper`.
- Updated wrong CSS mixin value in the `paper-autocomplete-suggestions` element.

Thanks to @jimivdw.

## Release 2.3.1 (2017-02-13)

### Bug Fixes
- The `--paper-input-container-focus-color` default value is no longer hardcoded to a specific color (`#2196f3`). 
Now it is set by default to `var(--primary-color)`.

## Release 2.3.0 (2017-02-08)

### New Features
- `paper-autocomplete` now has a new option: `placeholder`.

## Release 2.2.1 (2017-02-08)

### Bug Fixes
- Fixed a typo in the code that was causing an error when calling `hideSuggestions()` method.

## Release 2.2.0 (2017-01-12)

### New Features
- Added new option `name` for integrating the autocomplete with an `iron-form`.

## Release 2.1.5 (2016-12-14)

### Bug Fixes
- Fixed option disableShowClear, option was not being behaving as documented, added tests for same. Thanks to @vidhill.

## Release 2.1.4 (2016-12-08)

### Bug Fixes
- Fixed when user pressed UP or DOWN with no results, a JavaScript error was thrown.

## Release 2.1.3 (2016-12-08)

### Bug Fixes
- Preventing the focus to switch from input field when autocomplete-suggestions is a child of an element with tabindex
and user clicks in the scrollbar to scroll over results.

## Release 2.1.2 (2016-12-07)

### Bug Fixes
- `text` and `value` were not set when a selection was made. This is now fixed. 

## Release 2.1.1 (2016-11-29)

### Bug Fixes
- Bumping version to avoid a possible version conflict with Beta and RC versions.

## Release 2.1.0 (2016-11-29)

### New Features
- `paper-autocomplete` has been split in two components: `paper-autocomplete` and `paper-autocomplete-suggestions`.
The second one is a new component containing all the logic related to the popup with suggestions: search, selection,
etc. This allows using the autocomplete functionality with any input field.
- Selection with the keyboard has been changed: now you can go from the first/last to the last/first pressing up/down keys.
- Added test to the component (at this moment, two A11Y tests are failing when the component is test with ShadowDom,
this issue is being investigated).

### Bug Fixes
- When user pressed `left` or `right` key when a component was highlighted, the state was reset. Now the popup is 
 ignoring those key events.

## Release 2.0.0 (2016-11-21)

### New Features
- It is now possible to specify custom templates for suggestions.
- You can now specify your own `queryFn` to filter suggestions according to your needs.
- Added `CHANGELOG.md`

### Breaking Change
- Property `useShadowDom` has been removed because now the component works in both modes without it. You can just remove
  it from your apps. However, if you have it, nothing will break, it will just be ignored.
  
### Bug Fixes
- `setOption()` method was not taking into account `textProperty` and `valueProperty` options.
