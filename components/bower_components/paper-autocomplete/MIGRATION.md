# Migration Guide

## Migrate from v2.x.x to 3.x.x
The breaking changes are all related to the use of *custom templates* and styling the items. If you do not use this
feature, then you do not need to perform any change to migrate to v3.x.x.

If that is not your case and you do use *custom templates*, then you need to migrate your code. 
From v3.x.x, this component is in *hybrid-mode*, which means it makes use of the new ShadowDom v1 `<slots>`. The main
difference with v0 and `<content>` tags is the way you can style the projected content. With the `::slotted()` selector
you can only target **top level distributed childs**. In practice this means that if you want to style your templates,
you need to move the style code inside the template tag that contains the custom template. And please pay special 
attention to Internet Explorer 11, which has a couple of known issues related to styles that are not caused by this
component.

So to migrate, you just need to move your `<style>` inside the template tag and adjust the selectors if needed. See
the `demo/account-autocomplete.html` file to see an example of how styling should be done so the component workt in both
Polymer 1.7+ and 2.x.

### Before v2.x.x:

```html
<dom-module id="account-autocomplete">
  <style>
    :host {
      display: block;
    }

    paper-item.account-item {
      padding: 8px 16px;
    }            
  </style>

  <template>
    <paper-autocomplete label="Select Account"
                        id="input-local"
                        no-label-float="true"
                        source="[[accounts]]"
                        text-property="accountNumber"
                        value-property="id">
        <template slot="autocomplete-custom-template">
          <paper-item class="account-item" on-tap="_onSelect" id$="[[_getSuggestionId(index)]]" role="option" aria-selected="false">
            <div>
              <div class="company-name">[[item.companyName]]</div>
              <div class="account-number">[[item.accountNumber]]</div>
              <div class="email">[[item.email]]</div>
            </div>
            <paper-ripple></paper-ripple>
          </paper-item>
        </template>
    </paper-autocomplete>
  </template>
</dom-module>
```

### After 3.x.x

```html
<dom-module id="account-autocomplete">
  <template>
    <paper-autocomplete label="Select Account"
                        id="input-local"
                        no-label-float="true"
                        source="[[accounts]]"
                        text-property="accountNumber"
                        value-property="id">
        <template slot="autocomplete-custom-template">
          <style>
            :host {
              display: block;
            }

            paper-item.account-item {
              padding: 8px 16px;
            }            
          </style>
          <paper-item class="account-item" on-tap="_onSelect" id$="[[_getSuggestionId(index)]]" role="option" aria-selected="false">
            <div>
              <div class="company-name">[[item.companyName]]</div>
              <div class="account-number">[[item.accountNumber]]</div>
              <div class="email">[[item.email]]</div>
            </div>
            <paper-ripple></paper-ripple>
          </paper-item>
        </template>
    </paper-autocomplete>
  </template>
</dom-module>
```
