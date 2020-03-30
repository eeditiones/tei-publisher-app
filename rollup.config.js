import resolve from '@rollup/plugin-node-resolve';
import { terser } from 'rollup-plugin-terser';
import analyze from 'rollup-plugin-analyzer';
import copy from 'rollup-plugin-copy';
import replace from '@rollup/plugin-replace';

const production = process.env.BUILD === 'production';

export default [
    {
        input: 'node_modules/tippy.js/dist/tippy.esm.js',
        output: {
            dir: 'node_modules/tippy.js/dist',
            format: 'es',
            sourcemap: false
        },
        plugins: [
            resolve(),
            replace({
                'process.env.NODE_ENV': JSON.stringify('production')
            })
        ]
    },
    {
        input: [
            '@teipublisher/pb-components/src/pb-components-bundle.js',
            '@teipublisher/pb-components/src/pb-leaflet-map.js',
            '@teipublisher/pb-components/src/pb-odd-editor.js',
            '@teipublisher/pb-components/src/pb-edit-app.js'
        ],
        output: {
            dir: 'resources/scripts',
            format: 'es',
            sourcemap: !production
        },
        plugins: [
            resolve(),
            production && terser(),
            replace({
                'process.env.NODE_ENV': JSON.stringify('production')
            }),
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
            }),
            analyze({
                summaryOnly: true
            })
        ]
    }
]