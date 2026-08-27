# frozen_string_literal: true

module Bali
  # Scaffolds a dashboard widget: the class, its four locale keys in every locale
  # the app has, and a test.
  #
  #   bin/rails g bali:widget LowStockItems --size medium
  #
  # The locale keys are the reason this exists. A widget's copy lives under
  # `widgets.<key>.{title,short_title,description,empty}` — four keys per widget,
  # per locale, that a host otherwise discovers from prose and forgets one of.
  # `description` in particular is only ever seen in a picker, so a missing one
  # surfaces late.
  class WidgetGenerator < Rails::Generators::NamedBase
    source_root File.expand_path("templates", __dir__)

    class_option :size, type: :string, default: "medium",
                        desc: "small, medium or large — the canvas the widget is drawn around"
    class_option :supports, type: :array, default: nil,
                            desc: "Sizes a user may choose (defaults to all three)"
    class_option :parent, type: :string, default: nil,
                          desc: "Base class (defaults to ApplicationWidget if you have one)"
    class_option :skip_test, type: :boolean, default: false
    class_option :skip_locales, type: :boolean, default: false

    def validate_sizes
      known = Bali::Widget::SIZES.map(&:to_s)
      unless known.include?(options[:size])
        raise Thor::Error, "--size must be one of: #{Bali::Widget::SIZES.join(', ')}"
      end

      unknown = Array(options[:supports]) - known
      raise Thor::Error, "--supports must be from: #{Bali::Widget::SIZES.join(', ')}" if unknown.any?
      return if options[:supports].nil? || options[:supports].include?(options[:size])

      raise Thor::Error, "--size #{options[:size]} must be one of --supports #{options[:supports].join(', ')}"
    end

    def create_widget
      template "widget.rb", File.join("app/widgets", "#{file_path}.rb")
    end

    def create_test
      return if options[:skip_test]

      template "widget_test.rb", File.join("test/widgets", "#{file_path}_test.rb")
    end

    # Every locale the app already has, rather than a hardcoded en: a host that
    # ships es and en wants both stubs, and finding out which one you forgot by
    # switching locale in production is the failure this avoids.
    def append_locale_keys
      return if options[:skip_locales]

      locales.each do |locale|
        path = "config/locales/widgets.#{locale}.yml"
        create_file(path, "#{locale}:\n  widgets:\n") unless File.exist?(path)
        inject_into_file(path, locale_block, after: "  widgets:\n")
      end
    end

    private

    # `LowStockItems` -> `low_stock_items`, the same derivation `Base.key` does.
    def widget_key = file_name

    def parent_class
      options[:parent] || (defined?(::ApplicationWidget) ? "ApplicationWidget" : "Bali::Widget::Base")
    end

    def locales
      found = Dir.glob(Rails.root.join("config/locales/*.yml")).map { |f| File.basename(f, ".yml").split(".").last }
      (found & I18n.available_locales.map(&:to_s)).presence || [ I18n.default_locale.to_s ]
    end

    def locale_block
      <<~YAML
        #{'    '}#{widget_key}:
        #{'      '}title: #{human_name}
        #{'      '}short_title: #{human_name}
        #{'      '}description: TODO — one line saying what this widget shows, for the picker
        #{'      '}empty: TODO — what to say when there is nothing to list
      YAML
    end
  end
end
