# frozen_string_literal: true

module Bali
  module BpmnEditor
    # Serves the FLAT strings table the island consumes as its `i18n` prop,
    # from `bali_view.bpmn_editor.island.*`. Its keys are the keys of
    # DEFAULT_I18N in app/components/bali/bpmn_editor/i18n.js, which fills any
    # key a host's override leaves out;
    # test/bali/components/bpmn_editor/translations_test.rb keeps both locales
    # and the JS table on the same keys.
    module Translations
      module_function

      # Fetched as a Hash so I18n performs no interpolation: `%{count}` and
      # `%{name}` are filled in by the island.
      def island(locale: I18n.locale)
        I18n.t("bali_view.bpmn_editor.island", locale: locale, raise: true)
            .to_h { |key, value| [ key.to_s, value.to_s ] }
      end
    end
  end
end
