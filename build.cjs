#!/usr/bin/env node
/**
 * Node.js alternative to build.xml for packaging a TEI Publisher app as .xar.
 * Keep exclusion patterns in sync with build.tpl.xml.
 */
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const { globSync } = require('glob');
const { zipSync } = require('fflate');

const ROOT = process.cwd();
const BUILD_DIR = 'build';

// Must stay in sync with build.tpl.xml <exclude> entries
const IGNORE_PATTERNS = [
    `${BUILD_DIR}/**`,
    '*.code-workspace',
    '.devcontainer/**',
    '**/.git/**',
    '.github/**',
    '**/.idea/**',
    '.vscode/**',
    '*.tmpl',
    '*.properties',
    'build.xml',
    'build.cjs',
    'README.md',
    'node_modules/**',
    'package*.json',
    '.existdb.json',
    '.gitignore',
    'gulpfile.js',
    '.devcontainer',
    'test/cypress/screenshots/**',
    'test/cypress/videos/**',
];

const args = process.argv.slice(2);
const isLocal = args.includes('--local');
const isRelease = args.includes('--release');
const clean = !args.includes('--no-clean');

function readPackageInfo() {
    const xml = fs.readFileSync(path.join(ROOT, 'expath-pkg.xml'), 'utf8');
    const abbrev = xml.match(/\babbrev="([^"]+)"/)?.[1];
    const version = xml.match(/\bversion="([^"]+)"/)?.[1];
    if (!abbrev || !version) {
        throw new Error('Could not read abbrev/version from expath-pkg.xml');
    }
    return { abbrev, version };
}

function runGit(args) {
    try {
        return execSync(['git', ...args].join(' '), {
            cwd: ROOT,
            encoding: 'utf8',
            stdio: ['ignore', 'pipe', 'ignore'],
        }).trim();
    } catch {
        return '';
    }
}

function getReleaseTokens() {
    if (!isRelease) {
        return {
            name: '',
            version: '',
            url: '',
            title: '',
            'commit-id': '',
            'commit-time': '',
        };
    }
    console.log('Calculating git revision info for release');
    const commitId = runGit(['rev-parse', 'HEAD']);
    const commitTime = commitId
        ? runGit(['show', '-s', '--format=%ct', commitId])
        : '';
    console.log(`git commit id: ${commitId}`);
    console.log(`git commit time: ${commitTime}`);
    return {
        name: '',
        version: '',
        url: '',
        title: '',
        'commit-id': commitId,
        'commit-time': commitTime,
    };
}

function replaceTokens(content, tokens) {
    let result = content;
    for (const [key, value] of Object.entries(tokens)) {
        result = result.replaceAll(`@${key}@`, value ?? '');
    }
    return result.replaceAll('&', '&amp;');
}

function ensureDir(dir) {
    fs.mkdirSync(dir, { recursive: true });
}

function copyFile(src, dest) {
    // Skip anything that is not a regular file. Symlinks (e.g. a linked
    // `.agents` dir), sockets and fifos are not part of the app and make
    // copyFileSync fail (ENOTSUP on sockets), so ignore them.
    if (!fs.lstatSync(src).isFile()) {
        return;
    }
    ensureDir(path.dirname(dest));
    fs.copyFileSync(src, dest);
}

function copyGlob(srcDir, destDir, pattern) {
    if (!fs.existsSync(srcDir)) {
        return;
    }
    const files = globSync(pattern, { cwd: srcDir, nodir: true });
    for (const file of files) {
        copyFile(path.join(srcDir, file), path.join(destDir, file));
    }
}

function copyTree(srcDir, destDir) {
    if (!fs.existsSync(srcDir)) {
        return;
    }
    copyGlob(srcDir, destDir, '**/*');
}

function cleanBuildDir() {
    const buildPath = path.join(ROOT, BUILD_DIR);
    if (fs.existsSync(buildPath)) {
        fs.rmSync(buildPath, { recursive: true, force: true });
    }
}

function stageApp(stagingDir, tokens) {
    ensureDir(stagingDir);

    const globOptions = {
        cwd: ROOT,
        nodir: true,
        dot: true,
        ignore: IGNORE_PATTERNS,
    };

    const files = new Set([
        ...globSync('*', globOptions),
        ...globSync('**/*', globOptions),
    ]);

    for (const relPath of files) {
        copyFile(path.join(ROOT, relPath), path.join(stagingDir, relPath));
    }

    const tmplFiles = globSync('*.xml.tmpl', { cwd: ROOT, nodir: true });
    for (const tmpl of tmplFiles) {
        const content = fs.readFileSync(path.join(ROOT, tmpl), 'utf8');
        const processed = replaceTokens(content, tokens);
        const target = tmpl.replace(/\.tmpl$/, '');
        fs.writeFileSync(path.join(stagingDir, target), processed, 'utf8');
        console.log(`Processed template ${tmpl} -> ${target}`);
    }
}

function vendorLocalWebcomponents(stagingDir) {
    const nm = path.join(ROOT, 'node_modules');
    const scriptsDir = path.join(nm, '@teipublisher/pb-components/dist');

    copyFile(
        path.join(nm, '@picocss/pico/css/pico.min.css'),
        path.join(stagingDir, 'resources/styles/pico.min.css')
    );

    const pbImages = path.join(nm, '@teipublisher/pb-components/images');
    const destImages = path.join(stagingDir, 'resources/images');
    copyGlob(pbImages, destImages, 'leaflet/**/*');
    copyGlob(pbImages, destImages, 'openseadragon/**/*');

    copyGlob(scriptsDir, path.join(stagingDir, 'resources/scripts'), '*.{js,map}');

    copyTree(
        path.join(nm, '@teipublisher/pb-components/css'),
        path.join(stagingDir, 'resources/css')
    );
    copyGlob(
        path.join(nm, '@jinntec/fore/resources'),
        path.join(stagingDir, 'resources/css'),
        '*.css'
    );

    copyTree(
        path.join(nm, '@teipublisher/pb-components/lib'),
        path.join(stagingDir, 'resources/lib')
    );
    copyGlob(
        path.join(nm, '@teipublisher/pb-components/dist'),
        path.join(stagingDir, 'resources/lib'),
        '*.{js,map}'
    );
    copyGlob(
        path.join(nm, '@jinntec/fore/dist'),
        path.join(stagingDir, 'resources/lib'),
        '*.{js,map}'
    );

    copyTree(
        path.join(nm, '@teipublisher/pb-components/i18n/common'),
        path.join(stagingDir, 'resources/i18n/common')
    );
}

function createXar(stagingDir, xarPath) {
    const entries = new Set([
        ...globSync('*', { cwd: stagingDir, nodir: true, dot: true }),
        ...globSync('**/*', { cwd: stagingDir, nodir: true, dot: true }),
    ]);
    const zipData = {};

    for (const relPath of entries) {
        const absPath = path.join(stagingDir, relPath);
        zipData[relPath.replace(/\\/g, '/')] = new Uint8Array(fs.readFileSync(absPath));
    }

    ensureDir(path.dirname(xarPath));
    fs.writeFileSync(xarPath, zipSync(zipData));
    console.log(`Built ${path.relative(ROOT, xarPath)} (${entries.size} files)`);
}

function main() {
    const { abbrev, version } = readPackageInfo();
    const stagingDir = path.join(ROOT, BUILD_DIR, `${abbrev}-${version}`);
    const xarPath = path.join(ROOT, BUILD_DIR, `${abbrev}-${version}.xar`);

    if (clean) {
        cleanBuildDir();
    }

    if (isLocal) {
        console.log('Running npm install for local web components...');
        execSync('npm install', { cwd: ROOT, stdio: 'inherit' });
    }

    const tokens = getReleaseTokens();
    stageApp(stagingDir, tokens);

    if (isLocal) {
        vendorLocalWebcomponents(stagingDir);
    }

    createXar(stagingDir, xarPath);
}

main();
