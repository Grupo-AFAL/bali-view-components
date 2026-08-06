# frozen_string_literal: true

module Bali
  module Gantt
    # Serves the FLAT strings table the Gantt island consumes as its `i18n`
    # prop (#705, decision D12) — the same pattern as the BlockEditor's
    # `translations` value: texts are server-rendered from the engine's
    # locales (`bali_view.gantt.island.*`), never hardcoded in the JS bundle.
    # The island keeps English defaults (ganttColors sibling `i18n.js`) so a
    # missing key degrades to English instead of breaking.
    #
    #   data: { gantt: { i18n_value: Bali::Gantt::Translations.island.to_json } }
    #
    # KEYS is the contract with the JS side: `i18n.js` DEFAULT_I18N must carry
    # exactly these keys. test/bali/components/gantt/translations_test.rb
    # keeps both sides and both locales honest.
    module Translations
      KEYS = %w[
        add_group add_group_hint add_item add_item_hint
        search_placeholder filter filter_by_status all
        columns show_columns
        col_name col_assignee_short col_assignee col_dates col_days col_status col_progress
        critical critical_hint deps deps_hint
        color color_by color_status color_assignee color_group color_priority
        zoom_label zoom_day zoom_week zoom_month
        today go_to_today zoom_in zoom_out fit fullscreen
        expand collapse
        selection_none selected items_count range_days critical_count progress_label
        resize_start resize_duration drag_dependency
        minimap_hint splitter_hint
        schedule_refreshed change_failed load_error
      ].freeze

      module_function

      # Fetches the subtree as a Hash so I18n performs NO interpolation: keys
      # like `selected` carry a literal "%{count}" the ISLAND interpolates
      # client-side, and a per-key I18n.t would raise
      # MissingInterpolationArgument on them.
      def island(locale: I18n.locale)
        table = I18n.t("bali_view.gantt.island", locale: locale, raise: true)
        KEYS.index_with { |key| table.fetch(key.to_sym).to_s }
      end
    end
  end
end
