'use strict';

var fs =                    require('fs'),
    gulp =                  require('gulp'),
    exist =                 require('gulp-exist'),
    newer =                 require('gulp-newer'),
    less =                  require('gulp-less'),
    del =                   require('del'),
    path =                  require('path'),
    sourcemaps =            require('gulp-sourcemaps'),
    LessAutoprefix =        require('less-plugin-autoprefix'),
    autoprefix =            new LessAutoprefix({ browsers: ['last 2 versions'] }),
    LessPluginCleanCSS =    require('less-plugin-clean-css'),
    cleanCSSPlugin =        new LessPluginCleanCSS({advanced: true}),

    input = {
        'styles':               'resources/css/style.less',
        'vendor_styles':        'resources/css/vendor/*',
        'scripts':              'resources/scripts/app.js',
        'riot':                 'resources/scripts/tags/*.tag',
        'vendor_scripts':       'resources/scripts/vendor/*',
        'html':                 '*.html',
        'images':               'resources/images/*',
        'fonts':                'resources/fonts/*',
        'templates':            'templates/**',
        'odd':                  'odd/*',
        'transform':            'transform/*',
        'modules':              'modules/**/*',
        'other':                '*{.xpr,.xqr,.xql,.xml,.xconf}',
        'components':           'components/*',
        'components_editor':    'components/editor/*',
        'components_test':      'components/test/**/*',
        'components_demo':      'components/demo/**/*',
        'gen_app_styles':       'resources/css/**/*',
        'gen_app_scripts':      'resources/scripts/**/*',
        'gen_app_templates':    'templates/*.html',
        'gen_app_pages':        '*.html'
    },
    output  = {
        'styles':               'resources/css',
        'vendor_styles':        'resources/css/vendor/*',
        'scripts':              'resources/scripts/**',
        'riot':                 'resources/scripts/tags/*.tag',
        'vendor_scripts':       'resources/scripts/vendor/*',
        'html':                 '.',
        'images':               'resources/images/*',
        'fonts':                'resources/fonts/*',
        'templates':            'templates',
        'odd':                  'resources/odd',
        'transform':            'transform/*',
        'modules':              'modules/**/*',
        'gen_app_styles':       'templates/basic/resources/css',
        'gen_app_scripts':      'templates/basic/resources/scripts',
        'gen_app_templates':    'templates/basic/templates',
        'gen_app_pages':        'templates/basic'
    }
;

// *************  existDB configuration *************** //

/*
var localConnectionOptions = {};

if (fs.existsSync('./local.node-exist.json')) {
    localConnectionOptions = require('./local.node-exist.json');
    console.log('read from localConnectionOptions', localConnectionOptions)
}

var exClient = exist.createClient(localConnectionOptions);

var targetConfiguration = {
    target: '/db/apps/tei-publisher/'
};
*/

exist.defineMimeTypes({
    'application/xml': ['odd']
});

var exClient = exist.createClient({
    host: 'localhost',
    port: '8080',
    path: '/exist/xmlrpc',
    basic_auth: {
        user: 'admin',
        pass: ''
    }
});

var baseUrl = '/db/apps/tei-publisher/';

// Default deployment configuration
var targetConfigurationDefault = {
    target: baseUrl,
    html5AsBinary: false
};

// Deploy non-well-formed files in components directory as binaries
var targetConfigurationComponents = {
    target: baseUrl + 'components/',
    html5AsBinary: true
};

// Deploy non-well-formed files in components directory as binaries
var targetConfigurationComponentsEditor = {
    target: baseUrl + 'components/editor/',
    html5AsBinary: true
};

// Deploy only well-formed files in components/demo directory
var targetConfigurationDemo = {
    target: baseUrl + 'components/demo/',
    html5AsBinary: false
};

// Deploy non-well-formed files in components/test directory as binaries
var targetConfigurationTest = {
    target: baseUrl + '/components/test/',
    html5AsBinary: true
};

// ****************  Styles ****************** //

gulp.task('build:styles', function(){
    return gulp.src(input.styles)
        .pipe(sourcemaps.init())
        .pipe(less({ plugins: [cleanCSSPlugin, autoprefix] }))
        .pipe(sourcemaps.write())
        .pipe(gulp.dest(output.styles))
});

gulp.task('deploy:vendor_styles', function () {
    console.log('deploying less and css files');
    return gulp.src(input.vendor_styles, {base: './'})
        .pipe(exClient.newer(targetConfigurationDefault))
        .pipe(exClient.dest(targetConfigurationDefault))
});

gulp.task('deploy:styles', ['build:styles', 'deploy:vendor_styles'], function () {
    console.log('deploying less and css files');
    return gulp.src('resources/css/**/*', {base: './'})
        .pipe(exClient.newer(targetConfigurationDefault))
        .pipe(exClient.dest(targetConfigurationDefault))
});

gulp.task('watch:styles', function () {
    console.log('watching less files');
    gulp.watch('resources/css/**/*.less', ['deploy:styles'])
});

// *************  Scripts *************** //

// Deploy javascript to existDB
gulp.task('deploy:vendor_scripts', function () {
    return gulp.src([
        output.vendor_scripts
    ], {base: '.'})
        .pipe(exClient.newer(targetConfigurationDefault))
        .pipe(exClient.dest(targetConfigurationDefault))
});

gulp.task('deploy:riot_scripts', function () {
    return gulp.src([
        output.riot
    ], {base: '.'})
        .pipe(exClient.newer(targetConfigurationDefault))
        .pipe(exClient.dest(targetConfigurationDefault))
});

gulp.task('deploy:scripts', ['deploy:vendor_scripts','deploy:riot_scripts'], function () {
    return gulp.src(output.scripts, {base: '.'})
        .pipe(exClient.newer(targetConfigurationDefault))
        .pipe(exClient.dest(targetConfigurationDefault))
});

// Watch scripts
gulp.task('watch:scripts', function () {
    console.log('watching scripts');
    gulp.watch(output.scripts, ['deploy:scripts'])
});

// *************  Templates *************** //

// Deploy templates
gulp.task('deploy:templates', function () {
    console.log('deploying templates');
    return gulp.src(input.templates, {base: './'})
        .pipe(exClient.newer(targetConfigurationDefault))
        .pipe(exClient.dest(targetConfigurationDefault))
});

// Watch templates
gulp.task('watch:templates', function () {
    console.log('watching templates');
    gulp.watch(input.templates, ['deploy:templates'])
});


// *************  HTML Pages *************** //

// Deploy HTML pages
gulp.task('deploy:html', function () {
    console.log('deploying html files');
    return gulp.src(input.html, {base: './'})
        .pipe(exClient.newer(targetConfigurationDefault))
        .pipe(exClient.dest(targetConfigurationDefault))
});

// Watch HTML pages
gulp.task('watch:html', function () {
    console.log('watching html files');
    gulp.watch(input.html, ['deploy:html'])
});


// *************  ODD Files *************** //

gulp.task('deploy:odd', function () {
    console.log('deploying directory "odd"');
    return gulp.src(input.odd, {base: './'})
        .pipe(exClient.newer(targetConfigurationDefault))
        .pipe(exClient.dest(targetConfigurationDefault))
});

gulp.task('watch:odd', function () {
    gulp.watch(input.odd, ['deploy:odd'])
});

// *************  Images *************** //

// Deploy Images
gulp.task('deploy:images', function () {
    return gulp.src(output.images, {base: '.'})
        .pipe(exClient.newer(targetConfigurationDefault))
        .pipe(exClient.dest(targetConfigurationDefault))
});

gulp.task('watch:images', function () {
    gulp.watch(output.images, ['deploy:images'])
});

// *************  Files in project root *************** //

gulp.task('deploy:other', function () {
    return gulp.src(input.other, {base: './'})
        .pipe(exClient.newer(targetConfigurationDefault))
        .pipe(exClient.dest(targetConfigurationDefault))
});

gulp.task('watch:other', function () {
    gulp.watch(input.other, ['deploy:other'])
});

// *************  Components ***************************//

gulp.task('watch:components', function () {
    gulp.watch([input.components, '!components/bower_components/**/*', '!components/demo', '!components/test'], ['deploy:components'])});

gulp.task('watch:components_test', function () {
    gulp.watch(input.components_test, ['deploy:components_test'])
});

gulp.task('watch:components_demo', function () {
    gulp.watch(input.components_demo, ['deploy:components_demo'])
});

gulp.task('watch:components_editor', function () {
    gulp.watch(input.components_editor, ['deploy:components_editor'])
});

gulp.task('deploy:components', function () {
    return gulp.src(input.components, {base: 'components'})
        .pipe(exClient.newer(targetConfigurationComponents))
        .pipe(exClient.dest(targetConfigurationComponents))
});

gulp.task('deploy:components_editor', function () {
    return gulp.src(input.components_editor, {base: 'components/editor'})
        .pipe(exClient.newer(targetConfigurationComponentsEditor))
        .pipe(exClient.dest(targetConfigurationComponentsEditor))
});

// Files in folder 'demo'
gulp.task('deploy:components_demo', function () {
    console.log('deploying all component demos to local existDB"');
    return gulp.src(input.components_demo, {base: 'components/demo'})
        .pipe(exClient.newer(targetConfigurationDemo))
        .pipe(exClient.dest(targetConfigurationDemo))
});

// Files in folder 'test'
gulp.task('deploy:components_test', function () {
    console.log('deploying all component tests to local existDB"');
    return gulp.src(input.components_test, {base: 'components/test'})
        .pipe(exClient.newer(targetConfigurationTest))
        .pipe(exClient.dest(targetConfigurationTest))
});

// *************  Copy resources to generated app folder *************** //

gulp.task('copy:styles', ['build:styles'], function () {
    console.log('copying styles to generated app folder "templates/basic/resources/css"');
    return gulp.src(input.gen_app_styles)
        .pipe(gulp.dest(output.gen_app_styles))
});

gulp.task('copy:scripts', function () {
    console.log('copying scripts to generated app folder "templates/basic/resources/scripts"');
    return gulp.src(input.gen_app_scripts)
        .pipe(gulp.dest(output.gen_app_scripts))
});

gulp.task('copy:templates', function () {
    console.log('copying templates to generated app folder "templates/basic/templates"');
    return gulp.src(input.gen_app_templates)
        .pipe(gulp.dest(output.gen_app_templates))
});

gulp.task('copy:pages', function () {
    console.log('copying pages to generated app folder "templates/basic"');
    return gulp.src(input.gen_app_pages)
        .pipe(gulp.dest(output.gen_app_pages))
});

gulp.task('copy', ['copy:styles', 'copy:scripts', 'copy:templates', 'copy:pages']);

// *************  General Tasks *************** //

gulp.task('deploy:modules', function () {
    console.log('deploying directory "modules"');
    return gulp.src(input.modules, {base: './'})
        .pipe(exClient.newer(targetConfigurationDefault))
        .pipe(exClient.dest(targetConfigurationDefault))
});

gulp.task('watch:modules', function () {
    gulp.watch(input.modules, ['deploy:modules'])
});

// Build task
gulp.task('build', [
    'build:styles'
]);

// Watch all changed files
gulp.task('watch', [
    'watch:styles',
    'watch:templates',
    'watch:modules',
    'watch:scripts',
    'watch:html',
    'watch:odd',
    'watch:other',
    'watch:components',
    'watch:components_editor',
    'watch:components_demo',
    'watch:components_test'
]);

// Deploy all files
gulp.task('deploy', [
    'deploy:styles',
    'deploy:scripts',
    'deploy:components',
    'deploy:components_test',
    'deploy:components_demo',
    'deploy:modules',
    'deploy:odd',
    'deploy:other'
]);

// Paths for deploying only to 'targetConfigurationDefault'
var pathsToDeploy = [
    output.odd
    ,input.html
    ,input.gen_app_templates
    ,output.styles
    ,input.vendor_styles
    ,input.other
    ,input.images
    ,output.scripts
    ,input.modules
    ,input.transform
    ,input.fonts
];

// Deploy all files to existDB
gulp.task('deploy-default', ['deploy:styles'], function () {
    console.log('deploying all files to local existDB"');
    return gulp.src(pathsToDeploy, {base: './'})
        .pipe(exClient.newer(targetConfigurationDefault))
        .pipe(exClient.dest(targetConfigurationDefault))
});

// TODO add test to gulp
gulp.task('test', () => {
    console.log('I will be a test one day, for now please see the documentation for how to run tests');
});

// Default task (which is called by 'npm gulp' task)
gulp.task('default', ['watch']);
