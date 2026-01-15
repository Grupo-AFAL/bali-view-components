# frozen_string_literal: true

# Rich Text Editor importmap configuration
# Include this in your config/importmap.rb only if you're using the Rich Text Editor:
#
#   # In config/importmap.rb
#   require 'bali/importmap/rich_text_editor'
#   Bali::Importmap::RichTextEditor.pin_all(self)
#
# Also ensure you have enabled the Rich Text Editor in your initializer:
#
#   # In config/initializers/bali.rb
#   Bali.config do |config|
#     config.rich_text_editor_enabled = true
#   end

module Bali
  module Importmap
    module RichTextEditor
      CDN_BASE = 'https://cdn.jsdelivr.net/npm'
      TIPTAP_VERSION = '3.0.7'
      PROSEMIRROR_TABLES_VERSION = '1.1.4'

      class << self
        def pin_all(importmap)
          pin_lowlight(importmap)
          pin_tiptap_core(importmap)
          pin_tiptap_extensions(importmap)
          pin_prosemirror(importmap)
          pin_utilities(importmap)
          pin_bali_rte(importmap)
        end

        private

        def pin_lowlight(importmap)
          importmap.pin 'lowlight', to: "#{CDN_BASE}/lowlight@3.3.0/+esm"
          importmap.pin 'devlop', to: "#{CDN_BASE}/devlop@1.1.0/+esm"

          # Highlight.js language packs
          %w[javascript json ruby css scss sql xml yaml].each do |lang|
            importmap.pin "highlight.js/lib/languages/#{lang}",
                          to: "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/es/languages/#{lang}.min.js"
          end
        end

        def pin_tiptap_core(importmap)
          importmap.pin '@tiptap/core',
                        to: "#{CDN_BASE}/@tiptap/core@#{TIPTAP_VERSION}/dist/index.min.js"
          importmap.pin '@tiptap/suggestion',
                        to: "#{CDN_BASE}/@tiptap/suggestion@#{TIPTAP_VERSION}/dist/index.min.js"
          importmap.pin '@tiptap/prosemirror-tables',
                        to: "#{CDN_BASE}/@tiptap/prosemirror-tables@#{PROSEMIRROR_TABLES_VERSION}/dist/index.cjs.min.js"
          importmap.pin '@tiptap/starter-kit',
                        to: "#{CDN_BASE}/@tiptap/starter-kit@#{TIPTAP_VERSION}/dist/index.min.js"

          # ProseMirror modules via TipTap
          pm_modules = %w[commands dropcursor gapcursor history keymap model schema-list state
                          tables transform view]
          pm_modules.each do |mod|
            importmap.pin "@tiptap/pm/#{mod}",
                          to: "#{CDN_BASE}/@tiptap/pm@#{TIPTAP_VERSION}/#{mod}/dist/index.js"
          end
          importmap.pin '@tiptap/pm',
                        to: "#{CDN_BASE}/@tiptap/pm@#{TIPTAP_VERSION}/state/dist/index.min.js"
        end

        def pin_tiptap_extensions(importmap)
          # Extensions with minified builds
          minified_extensions = %w[
            blockquote bold bullet-list code-block code color document dropcursor
            gapcursor hard-break heading history horizontal-rule image italic
            link list-item mention ordered-list paragraph placeholder strike
            table-cell table-header table-row table text-align text-style text
          ]

          minified_extensions.each do |ext|
            importmap.pin "@tiptap/extension-#{ext}",
                          to: "#{CDN_BASE}/@tiptap/extension-#{ext}@#{TIPTAP_VERSION}/dist/index.min.js"
          end

          # Extensions with ESM or non-minified builds
          importmap.pin '@tiptap/extension-bubble-menu',
                        to: "#{CDN_BASE}/@tiptap/extension-bubble-menu@#{TIPTAP_VERSION}/+esm"
          importmap.pin '@tiptap/extension-code-block-lowlight',
                        to: "#{CDN_BASE}/@tiptap/extension-code-block-lowlight@#{TIPTAP_VERSION}/dist/index.js"
          importmap.pin '@tiptap/extension-underline',
                        to: "#{CDN_BASE}/@tiptap/extension-underline@#{TIPTAP_VERSION}/+esm"
        end

        def pin_prosemirror(importmap)
          prosemirror_packages = {
            'prosemirror-changeset' => '2.3.1',
            'prosemirror-collab' => '1.3.1',
            'prosemirror-commands' => '1.7.1',
            'prosemirror-dropcursor' => '1.8.2',
            'prosemirror-gapcursor' => '1.3.2',
            'prosemirror-history' => '1.4.1',
            'prosemirror-inputrules' => '1.5.0',
            'prosemirror-keymap' => '1.2.3',
            'prosemirror-markdown' => '1.13.2',
            'prosemirror-menu' => '1.2.5',
            'prosemirror-model' => '1.25.2',
            'prosemirror-schema-basic' => '1.2.4',
            'prosemirror-schema-list' => '1.5.1',
            'prosemirror-state' => '1.4.3',
            'prosemirror-tables' => '1.7.1',
            'prosemirror-trailing-node' => '3.0.0',
            'prosemirror-transform' => '1.10.4',
            'prosemirror-view' => '1.40.1'
          }

          prosemirror_packages.each do |pkg, version|
            suffix = pkg == 'prosemirror-trailing-node' ? 'prosemirror-trailing-node.js' : 'index.min.js'
            importmap.pin pkg, to: "#{CDN_BASE}/#{pkg}@#{version}/dist/#{suffix}"
          end
        end

        def pin_utilities(importmap)
          importmap.pin 'linkifyjs', to: "#{CDN_BASE}/linkifyjs@4.3.2/+esm"
          importmap.pin 'orderedmap', to: "#{CDN_BASE}/orderedmap@2.1.1/dist/index.min.js"
          importmap.pin 'w3c-keyname', to: "#{CDN_BASE}/w3c-keyname@2.2.8/index.min.js"
          importmap.pin 'rope-sequence', to: "#{CDN_BASE}/rope-sequence@1.3.4/dist/index.min.js"
          importmap.pin 'markdown-it', to: "#{CDN_BASE}/markdown-it@14.1.0/dist/markdown-it.min.js"
          importmap.pin 'crelt', to: "#{CDN_BASE}/crelt@1.0.6/index.min.js"
          importmap.pin '@remirror/core-constants',
                        to: "#{CDN_BASE}/@remirror/core-constants@3.0.0/dist/remirror-core-constants.js"
          importmap.pin 'escape-string-regexp',
                        to: "#{CDN_BASE}/escape-string-regexp@5.0.0/index.min.js"
        end

        def pin_bali_rte(importmap)
          importmap.pin 'bali/rich_text_editor', to: 'bali/rich_text_editor/index.js'

          # JavaScript modules
          js_modules = %w[
            useDefaults useImage useLink useMarks useMention useNodes useSlashCommands useTable lowlight
          ]
          js_modules.each do |mod|
            importmap.pin "bali/rich_text_editor/#{mod}",
                          to: "bali/rich_text_editor/javascript/#{mod}.js"
          end

          # Extensions
          importmap.pin 'bali/rich_text_editor/extensions/slashCommands',
                        to: 'bali/rich_text_editor/javascript/extensions/slashCommands.js'

          # Suggestions
          suggestions = %w[commandsOptions pagesOptions popupListComponent renderer]
          suggestions.each do |sug|
            snake_case = sug.gsub(/([A-Z])/, '_\1').downcase.delete_prefix('_')
            importmap.pin "bali/rich_text_editor/suggestions/#{sug}",
                          to: "bali/rich_text_editor/javascript/suggestions/#{snake_case}.js"
          end
        end
      end
    end
  end
end
