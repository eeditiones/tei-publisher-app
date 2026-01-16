#!/usr/bin/env node

/**
 * Script to generate markdown documentation for theme settings
 * Reads config.json and schema/jinks.json to create a table of all theme properties
 * 
 * Usage:
 *   node generate-theme-docs.js [options]
 *   node generate-theme-docs.js <config.json> <output-dir>
 * 
 * Options:
 *   -c, --config <path>    Path to config.json file (default: ./config.json)
 *   -o, --output <dir>    Output directory for README.md (default: ./doc)
 *   -s, --schema <path>   Path to schema file (default: ../../schema/jinks.json relative to config)
 *   -h, --help            Show this help message
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Parse command line arguments
function parseArgs() {
    const args = process.argv.slice(2);
    let configPath = null;
    let outputDir = null;
    let schemaPath = null;
    
    // Check for help flag
    if (args.includes('-h') || args.includes('--help')) {
        console.log(`Usage: node generate-theme-docs.js [options]
  node generate-theme-docs.js <config.json> <output-dir>

Options:
  -c, --config <path>    Path to config.json file (default: ./config.json)
  -o, --output <dir>     Output directory for README.md (default: ./doc)
  -s, --schema <path>    Path to schema file (default: ../../schema/jinks.json relative to config)
  -h, --help             Show this help message

Examples:
  node generate-theme-docs.js
  node generate-theme-docs.js ./config.json ./doc
  node generate-theme-docs.js --config ../other-profile/config.json --output ../other-profile/doc
`);
        process.exit(0);
    }
    
    // Parse flags
    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        if (arg === '-c' || arg === '--config') {
            configPath = args[++i];
        } else if (arg === '-o' || arg === '--output') {
            outputDir = args[++i];
        } else if (arg === '-s' || arg === '--schema') {
            schemaPath = args[++i];
        } else if (!arg.startsWith('-') && !configPath) {
            // First positional argument is config path
            configPath = arg;
        } else if (!arg.startsWith('-') && !outputDir) {
            // Second positional argument is output directory
            outputDir = arg;
        }
    }
    
    // Set defaults
    if (!configPath) {
        configPath = path.join(__dirname, 'config.json');
    } else {
        // Resolve relative paths
        configPath = path.isAbsolute(configPath) ? configPath : path.resolve(process.cwd(), configPath);
    }
    
    if (!outputDir) {
        outputDir = path.join(path.dirname(configPath), 'doc');
    } else {
        // Resolve relative paths
        outputDir = path.isAbsolute(outputDir) ? outputDir : path.resolve(process.cwd(), outputDir);
    }
    
    if (!schemaPath) {
        // Default: ../../schema/jinks.json relative to config.json location
        schemaPath = path.join(path.dirname(configPath), '../../schema/jinks.json');
    } else {
        // Resolve relative paths
        schemaPath = path.isAbsolute(schemaPath) ? schemaPath : path.resolve(process.cwd(), schemaPath);
    }
    
    return { configPath, outputDir, schemaPath };
}

const { configPath, outputDir, schemaPath } = parseArgs();
const readmePath = path.join(outputDir, 'README.md');

// Validate paths exist
if (!fs.existsSync(configPath)) {
    console.error(`Error: config.json not found at: ${configPath}`);
    process.exit(1);
}

if (!fs.existsSync(schemaPath)) {
    console.error(`Error: schema file not found at: ${schemaPath}`);
    process.exit(1);
}

// Read JSON files
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
const schema = JSON.parse(fs.readFileSync(schemaPath, 'utf8'));

/**
 * Flatten a nested object into dot-notation paths
 * @param {object} obj - The object to flatten
 * @param {string} prefix - Prefix for the path
 * @returns {Array<{path: string, value: any}>} Array of path-value pairs
 */
function flattenObject(obj, prefix = '') {
    const result = [];
    
    for (const [key, value] of Object.entries(obj)) {
        const fullPath = prefix ? `${prefix}.${key}` : key;
        
        if (value !== null && typeof value === 'object' && !Array.isArray(value)) {
            // Recursively flatten nested objects
            result.push(...flattenObject(value, fullPath));
        } else {
            // Leaf value
            result.push({ path: fullPath, value });
        }
    }
    
    return result;
}

/**
 * Get description from schema for a given path
 * @param {object} schemaObj - Schema object to search
 * @param {string[]} pathParts - Array of path parts
 * @returns {string|null} Description or null if not found
 */
function getDescriptionFromSchema(schemaObj, pathParts) {
    if (!schemaObj || !pathParts || pathParts.length === 0) {
        return null;
    }
    
    const [first, ...rest] = pathParts;
    
    // Navigate to the next level
    if (schemaObj.properties && schemaObj.properties[first]) {
        const nextSchema = schemaObj.properties[first];
        
        // If this is the last part, get its description
        if (rest.length === 0) {
            return nextSchema.description || null;
        }
        
        // Otherwise, continue navigating
        return getDescriptionFromSchema(nextSchema, rest);
    }
    
    // Check patternProperties (for dynamic keys like palettes)
    if (schemaObj.patternProperties) {
        for (const patternSchema of Object.values(schemaObj.patternProperties)) {
            if (rest.length === 0) {
                return patternSchema.description || null;
            }
            const desc = getDescriptionFromSchema(patternSchema, rest);
            if (desc) return desc;
        }
    }
    
    return null;
}

/**
 * Format value for display in markdown
 * @param {any} value - The value to format
 * @returns {string} Formatted value
 */
function formatValue(value) {
    if (value === null) {
        return '`null`';
    }
    if (value === undefined) {
        return '`undefined`';
    }
    if (typeof value === 'string') {
        return `\`"${value}"\``;
    }
    if (typeof value === 'boolean') {
        return `\`${value}\``;
    }
    if (typeof value === 'number') {
        return `\`${value}\``;
    }
    if (Array.isArray(value)) {
        return `\`[${value.length} items]\``;
    }
    if (typeof value === 'object') {
        return `\`{object}\``;
    }
    return String(value);
}

// Get theme object from config
const theme = config.theme;
if (!theme) {
    console.error('No theme object found in config.json');
    process.exit(1);
}

// Get theme schema
const themeSchema = schema.properties.theme;
if (!themeSchema) {
    console.error('No theme schema found in jinks.json');
    process.exit(1);
}

// Flatten theme object
const flattened = flattenObject(theme);

// Sort by path for better readability
flattened.sort((a, b) => a.path.localeCompare(b.path));

// Generate markdown table content
let tableContent = `| Property | Description | Default |
|----------|-------------|-------\n`;

for (const item of flattened) {
    const pathParts = item.path.split('.');
    const description = getDescriptionFromSchema(themeSchema, pathParts) || '*No description available*';
    const value = formatValue(item.value);
    
    // Escape pipe characters in description
    const escapedDescription = description.replace(/\|/g, '\\|');
    
    tableContent += `| \`${item.path}\` | ${escapedDescription} | ${value} |\n`;
}

// Get relative paths for the note
const configRelativePath = path.relative(process.cwd(), configPath);
const schemaRelativePath = path.relative(process.cwd(), schemaPath);
tableContent += `\n> **Note:** Values shown are from \`${configRelativePath}\`. Descriptions are from \`${schemaRelativePath}\`. This section is auto-generated by \`generate-theme-docs.js\`.\n`;

// Marker patterns to identify the generated section
const START_MARKER_PATTERN = /<!--\s*START:.*?-->/;
const END_MARKER_PATTERN = /<!--\s*END:.*?-->/;

// Ensure output directory exists
if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
    console.log(`Created output directory: ${outputDir}`);
}

// Read existing README.md
if (!fs.existsSync(readmePath)) {
    console.error(`Error: README.md not found at: ${readmePath}`);
    console.error(`Please create a README.md file with START and END markers (e.g., <!-- START: theme-docs --> and <!-- END: theme-docs -->).`);
    process.exit(1);
}

let readmeContent = fs.readFileSync(readmePath, 'utf8');

// Check if markers exist
const startMarkerMatch = readmeContent.match(START_MARKER_PATTERN);
const endMarkerMatch = readmeContent.match(END_MARKER_PATTERN);

if (!startMarkerMatch) {
    console.error(`Error: Start marker matching \`<!--\\s*START:.*-->\` not found in README.md`);
    console.error(`Please add a marker like: <!-- START: theme-docs -->`);
    process.exit(1);
}

if (!endMarkerMatch) {
    console.error(`Error: End marker matching \`<!--\\s*END:.*-->\` not found in README.md`);
    console.error(`Please add a marker like: <!-- END: theme-docs -->`);
    process.exit(1);
}

// Replace content between the START and END markers
const startMarker = startMarkerMatch[0];
const endMarker = endMarkerMatch[0];

// Escape special regex characters in the markers
const escapedStartMarker = startMarker.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const escapedEndMarker = endMarker.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const markerRegex = new RegExp(
    `(${escapedStartMarker})[\\s\\S]*?(${escapedEndMarker})`,
    'g'
);

if (markerRegex.test(readmeContent)) {
    readmeContent = readmeContent.replace(
        markerRegex,
        `$1\n\n${tableContent}\n\n$2`
    );
} else {
    console.error(`Error: Could not find content between markers in README.md`);
    console.error(`Found start marker: ${startMarker}`);
    console.error(`Found end marker: ${endMarker}`);
    process.exit(1);
}

// Write updated README.md
fs.writeFileSync(readmePath, readmeContent, 'utf8');

console.log(`✓ Injected theme documentation into: ${readmePath}`);
console.log(`  Total properties: ${flattened.length}`);

