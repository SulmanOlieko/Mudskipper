const esbuild = require('esbuild');
const path = require('path');

esbuild.build({
  entryPoints: ['entry.js'],
  bundle: true,
  outfile: '../cm6-bundle.js',
  format: 'iife',
  globalName: 'MudskipperVisualEditor',
  minify: true,
  sourcemap: true,
  loader: {
    '.js': 'jsx',
    '.mjs': 'jsx',
    '.ts': 'ts',
    '.tsx': 'tsx',
    '.svg': 'text'
  },
  tsconfig: 'tsconfig.json',
  jsx: 'automatic',
  define: {
    'import.meta.url': 'undefined',
    'process.env.NODE_ENV': '"production"'
  },
  alias: {
    '@': path.resolve(__dirname, 'frontend/js'),
    '@ol-types': path.resolve(__dirname, 'types'),
    '@modules': path.resolve(__dirname, 'modules'),
    '@overleaf/o-error': path.resolve(__dirname, 'stubs/o-error.js')
  }
}).catch(() => process.exit(1));
