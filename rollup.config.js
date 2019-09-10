import resolve from 'rollup-plugin-node-resolve';
import { terser } from 'rollup-plugin-terser';
import analyze from 'rollup-plugin-analyzer';

// `npm run build` -> `production` is true
// `npm run dev` -> `production` is false
const production = process.env.PRODUCTION;

export default {
	input: 'resources/scripts/deps.js',
	output: {
		file: 'resources/scripts/bundle.js',
		format: 'iife', // immediately-invoked function expression — suitable for <script> tags
		sourcemap: true
	},
	plugins: [
		resolve(), // tells Rollup how to find date-fns in node_modules
		production && terser(), // minify, but only in production
		analyze({
			summaryOnly: true
		})
	]
};
