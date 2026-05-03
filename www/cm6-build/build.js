const esbuild = require('esbuild');
const path = require('path');

const commonConfig = {
  bundle: true,
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
};

// Build the main bundle
esbuild.build({
  ...commonConfig,
  entryPoints: ['entry.js'],
  outfile: '../cm6-bundle.js',
  format: 'iife',
  globalName: 'MudskipperVisualEditor',
}).catch(() => process.exit(1));

// Build the LaTeX linter worker
esbuild.build({
  ...commonConfig,
  entryPoints: ['frontend/js/features/source-editor/languages/latex/linter/latex-linter.worker.ts'],
  outfile: '../latex-linter.worker.js',
  format: 'iife',
}).catch(() => process.exit(1));
