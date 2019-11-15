import resolve from 'rollup-plugin-node-resolve';
import { terser } from 'rollup-plugin-terser';
import analyze from 'rollup-plugin-analyzer';
import copy from 'rollup-plugin-copy';

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
		copy({
			targets: [
				{
					src: 'node_modules/@teipublisher/pb-components/assets/leaflet/*.css',
					dest: 'resources/css/vendor'
				},
				{
					src: 'node_modules/@teipublisher/pb-components/assets/leaflet/*.png',
					dest: 'resources/images/leaflet'
				},
				{
					src: 'node_modules/@teipublisher/pb-components/assets/openseadragon/*.png',
					dest: 'resources/images/openseadragon'
				}
			]
		}),
		resolve(), // tells Rollup how to find date-fns in node_modules
		production && terser(), // minify, but only in production
		analyze({
			summaryOnly: true
		})
	]
};
