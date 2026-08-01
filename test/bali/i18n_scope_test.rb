# frozen_string_literal: true

require "test_helper"

class BaliI18nScopeTest < ActiveSupport::TestCase
  def test_relative_keys_resolve_under_the_gem_root_scope
    assert_equal("bali_view.rate", Bali::Rate::Component.virtual_path)
    assert_equal("bali_view.drawer", Bali::Drawer::Component.virtual_path)
  end

  # The class-name half of the scope drops its leading "bali" — the namespace
  # already carries it — but keeps every level below it.
  def test_nested_components_keep_their_path
    assert_equal(
      "bali_view.gantt_chart.task_actions",
      Bali::GanttChart::TaskActions::Component.virtual_path
    )
  end

  def test_every_key_exists_in_both_locales
    en = flatten(YAML.load_file(Bali::Engine.root.join("config/locales/bali_view.en.yml"))["en"])
    es = flatten(YAML.load_file(Bali::Engine.root.join("config/locales/bali_view.es.yml"))["es"])

    assert_equal([], en.keys - es.keys, "claves sin traducción al español")
    assert_equal([], es.keys - en.keys, "claves sin texto en inglés")
  end

  # Rails::Engine registers config/locales with engines BEFORE the app, so the
  # host's own file wins. An initializer appending the same paths to
  # i18n.load_path by hand puts them back last and silently beats the host.
  def test_a_host_can_override_a_bali_string
    engine_locales = Bali::Engine.root.join("config", "locales").to_s
    app_locales = Rails.root.join("config", "locales").to_s

    positions = I18n.load_path.map(&:to_s).each_with_index.filter_map do |path, index|
      index if path.start_with?(engine_locales)
    end
    app_position = I18n.load_path.map(&:to_s).index { |path| path.start_with?(app_locales) }

    assert positions.any?, "los locales de la gema no están en el load path"
    assert app_position, "los locales de la app no están en el load path"
    assert positions.max < app_position,
           "los locales de la gema cargan después de los de la app: el host no puede sobrescribir"
  end

  private

  def flatten(node, prefix = nil)
    return { prefix => node } unless node.is_a?(Hash)

    node.each_with_object({}) do |(key, value), acc|
      acc.merge!(flatten(value, [ prefix, key ].compact.join(".")))
    end
  end
end
