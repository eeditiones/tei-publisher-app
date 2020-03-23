import resolve from '@rollup/plugin-node-resolve';
import { terser } from 'rollup-plugin-terser';
import copy from 'rollup-plugin-copy';

const production = process.env.BUILD === 'production';

export default {
    input: [
        '@teipublisher/pb-components/src/pb-components-bundle.js',
        '@teipublisher/pb-components/src/pb-leaflet-map.js'
        // add your own bundle for components:
        // './components/pb-edit-app.js'
    ],
    output: {
        dir: 'resources/scripts',
        format: 'es',
        sourcemap: true
    },
    plugins: [
        resolve(),
        production && terser(),
        copy({
            targets: [
                {
                    src: './node_modules/leaflet/dist/leaflet.css',
                    dest: 'resources/css/leaflet'
                },
                {
                    src: './node_modules/leaflet/dist/images/*',
                    dest: 'resources/images/leaflet'
                },
                {
                    src: './node_modules/openseadragon/build/openseadragon/images/*',
                    dest: 'resources/images/openseadragon'
                },
                {
                    src: './node_modules/openseadragon/build/openseadragon/openseadragon.min.js',
                    dest: 'resources/lib/'
                },
                {
                    src: './node_modules/prismjs/themes/*',
                    dest: 'resources/css/prismjs'
                },
                {
                    src: './node_modules/@teipublisher/pb-components/i18n/common/*',
                    dest: './resources/i18n/common'
                }
            ]
        })
    ]
}