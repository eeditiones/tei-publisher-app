'use strict';

var gulp = require('gulp');
var exist = require('gulp-exist');
var webdriver = require('gulp-webdriver');

var client = exist.createClient({
    host: 'localhost',
    port: 8080,
    path: '/exist/xmlrpc',
    basic_auth: { user: 'admin', pass: '' }
});

gulp.task('test:upload-xar', function() {
    return gulp.src("../build/*.xar").pipe(
        client.dest({
            "target": "/db/_pkgs"
        })
    );
});

gulp.task('test:deploy', ['test:upload-xar'], function() {
    return gulp.src("deploy.xql").pipe(
        client.query()
    );
});

gulp.task('test', ['test:deploy'], function() {
    return gulp.src('wdio.conf.js').pipe(webdriver());
});

gulp.task('default', ['test']);