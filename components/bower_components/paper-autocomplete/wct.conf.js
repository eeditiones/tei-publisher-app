/* eslint-env node, es6 */
module.exports = {
  suites: ['test'],
  plugins: {
    local: {
      disabled: true,
      browsers: ['chrome', 'firefox']
    },
    sauce: {
      disabled: true,
      name: 'paper-autocomplete',
      browsers: [
        {
          browserName: 'chrome',
          platform: 'Windows 7',
          version: 'latest'
        }, {
          browserName: 'firefox',
          platform: 'Windows 7',
          version: 'latest'
        }, {
          browserName: 'internet explorer',
          platform: 'Windows 7',
          version: '11.0'
        }, {
          browserName: 'microsoftedge',
          platform: 'Windows 10',
          version: ''
        }, {
          browserName: 'safari',
          platform: 'macOS 10.12',
          version: '10.0'
        }, {
          browserName: 'safari',
          platform: 'OS X 10.11',
          version: '9.0'
        }
      ]
    }
  }
};
