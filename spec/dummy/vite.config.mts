import { defineConfig } from 'vite'
import { resolve, dirname } from 'path'
import { fileURLToPath } from 'url'
import RubyPlugin from 'vite-plugin-ruby'
// StimulusHMR disabled - causes "application is not defined" errors with Bali's export strategy
// import StimulusHMR from 'vite-plugin-stimulus-hmr'
import FullReload from 'vite-plugin-full-reload'

const __dirname = dirname(fileURLToPath(import.meta.url))

// Bali gem is 2 levels up from spec/dummy
const baliGemPath = resolve(__dirname, '../..')

export default defineConfig({
  plugins: [
    RubyPlugin(),
    // StimulusHMR disabled - causes "application is not defined" errors
    FullReload([
      'app/views/**/*.erb',
      'app/components/**/*.erb',
      `${baliGemPath}/app/components/**/*.erb`
    ])
  ],
  resolve: {
    alias: [
      // Main Bali entry points - uses package.json exports
      { find: 'bali', replacement: resolve(baliGemPath, 'app/frontend/bali') },
      { find: 'bali/charts', replacement: resolve(baliGemPath, 'app/frontend/bali/charts.js') },
      { find: 'bali/gantt', replacement: resolve(baliGemPath, 'app/frontend/bali/gantt.js') },
      { find: 'bali/rich-text-editor', replacement: resolve(baliGemPath, 'app/frontend/bali/rich-text-editor.js') },
      // Explicit npm package aliases (needed for imports from gem path)
      { find: 'tippy.js', replacement: resolve(__dirname, 'node_modules/tippy.js') },
      { find: 'sortablejs', replacement: resolve(__dirname, 'node_modules/sortablejs') },
      { find: 'chart.js', replacement: resolve(__dirname, 'node_modules/chart.js') },
      { find: '@glidejs/glide', replacement: resolve(__dirname, 'node_modules/@glidejs/glide') },
      { find: '@popperjs/core', replacement: resolve(__dirname, 'node_modules/@popperjs/core') },
      { find: 'date-fns', replacement: resolve(__dirname, 'node_modules/date-fns') },
      { find: 'rrule', replacement: resolve(__dirname, 'node_modules/rrule') },
      { find: 'lodash.debounce', replacement: resolve(__dirname, 'node_modules/lodash.debounce') },
      { find: 'lodash.throttle', replacement: resolve(__dirname, 'node_modules/lodash.throttle') },
      { find: '@rails/request.js', replacement: resolve(__dirname, 'node_modules/@rails/request.js') },
      { find: '@googlemaps/markerclusterer', replacement: resolve(__dirname, 'node_modules/@googlemaps/markerclusterer') },
      { find: 'slim-select', replacement: resolve(__dirname, 'node_modules/slim-select') },
      { find: 'interactjs', replacement: resolve(__dirname, 'node_modules/interactjs') },
      { find: '@rails/activestorage', replacement: resolve(__dirname, 'node_modules/@rails/activestorage') }
    ],
    // Ensure dependencies used by Bali are resolved from dummy app's node_modules
    dedupe: [
      '@hotwired/stimulus',
      '@hotwired/turbo',
      'flatpickr',
      'chart.js',
      'sortablejs',
      'lodash.debounce',
      'lodash.throttle',
      '@rails/request.js',
      'date-fns',
      'rrule',
      'tippy.js',
      '@popperjs/core',
      '@glidejs/glide'
    ]
  },
  // Optimize dependencies that Bali uses
  optimizeDeps: {
    include: [
      '@hotwired/stimulus',
      '@hotwired/turbo',
      'flatpickr',
      'chart.js',
      'sortablejs',
      'lodash.debounce',
      'lodash.throttle',
      '@rails/request.js',
      'date-fns',
      'rrule',
      'tippy.js',
      '@popperjs/core',
      '@glidejs/glide'
    ]
  },
  build: {
    // Allow dynamic imports from gem path to resolve npm packages
    commonjsOptions: {
      include: [/node_modules/]
    }
  },
  server: {
    // Allow serving files from the Bali gem
    fs: {
      allow: [
        '.',
        baliGemPath
      ]
    }
  }
})
