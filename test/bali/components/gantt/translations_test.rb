# frozen_string_literal: true

require "test_helper"

# Bali::Gantt::Translations serves the island's `i18n` prop from
# bali_view.gantt.island.* (#705, D12). Three things can silently rot: a
# locale losing a key (the island would fall back to English mid-sentence),
# the Ruby KEYS list and the JS DEFAULT_I18N table drifting apart, and I18n
# interpolating the %{count}-style placeholders the CLIENT is supposed to
# fill. Each gets pinned here.
class BaliGanttTranslationsTest < ActiveSupport::TestCase
  JS_TABLE = Rails.root.join("../../app/components/bali/gantt/i18n.js")

  def test_island_serves_every_key_in_both_locales
    %i[en es].each do |locale|
      table = Bali::Gantt::Translations.island(locale: locale)
      assert_equal Bali::Gantt::Translations::KEYS.sort, table.keys.sort,
        "locale #{locale} lost keys"
      table.each do |key, value|
        assert value.is_a?(String) && value.present?,
          "#{locale}/#{key} está vacío o no es String: #{value.inspect}"
      end
    end
  end

  def test_keys_match_the_js_default_table
    js_keys = JS_TABLE.read[/DEFAULT_I18N = \{(.*?)\n\}/m, 1]
                      .scan(/^  ([a-z0-9_]+):/).flatten
    assert_equal js_keys.sort, Bali::Gantt::Translations::KEYS.sort,
      "Translations::KEYS y DEFAULT_I18N (i18n.js) divergieron"
  end

  def test_placeholders_reach_the_client_uninterpolated
    table = Bali::Gantt::Translations.island(locale: :en)
    assert_includes table["selected"], "%{count}"
    assert_includes table["items_count"], "%{count}"
    assert_includes table["progress_label"], "%{percent}"
  end
end
