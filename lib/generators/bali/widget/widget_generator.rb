# frozen_string_literal: true

module Bali
  # Scaffolds a dashboard widget: the class, its four locale keys in every locale
  # the app has, and a test.
  #
  #   bin/rails g bali:widget LowStockItems --pattern list --size medium
  #
  # THE PATTERN IS THE SUPERCLASS. `--pattern` does not write a declaration the
  # class could later contradict; it picks which of the five bases the widget
  # inherits from, and that choice is what supplies its declarations and its
  # declarations. So the scaffold is the documentation: a `trend` widget is
  # generated with `t.current` raising and `t.previous` present, because those are
  # exactly what a trend widget owes the card.
  #
  # The locale keys are the other reason this exists. A widget's copy lives under
  # `widgets.<key>.{title,short_title,description,empty}` — four keys per widget,
  # per locale, that a host otherwise discovers from prose and forgets one of.
  # `description` in particular is only ever seen in a picker, so a missing one
  # surfaces late.
  class WidgetGenerator < Rails::Generators::NamedBase
    source_root File.expand_path("templates", __dir__)

    # Named for the base each one picks, so `--pattern trend` and
    # `Bali::Widget::TrendBase` are the same word. A separate vocabulary here
    # ("metric", "stat") would be a second name for a class that already has one.
    PATTERNS = {
      "value" => "ValueBase",
      "list" => "ListBase",
      "trend" => "TrendBase",
      "progress" => "ProgressBase",
      "check" => "CheckBase"
    }.freeze

    class_option :pattern, type: :string, default: "list",
                           desc: "#{PATTERNS.keys.join(', ')} — which base the widget inherits from"
    class_option :size, type: :string, default: "medium",
                        desc: "small, medium or large — the canvas the widget is drawn around"
    class_option :supports, type: :array, default: nil,
                            desc: "Sizes a user may choose (defaults to the pattern's own set)"
    class_option :skip_test, type: :boolean, default: false
    class_option :skip_locales, type: :boolean, default: false

    def validate_pattern
      return if PATTERNS.key?(options[:pattern])

      raise Thor::Error, "--pattern must be one of: #{PATTERNS.keys.join(', ')}"
    end

    def validate_sizes
      known = Bali::Widget::SIZES.map(&:to_s)
      unless known.include?(options[:size])
        raise Thor::Error, "--size must be one of: #{Bali::Widget::SIZES.join(', ')}"
      end

      unknown = Array(options[:supports]) - known
      raise Thor::Error, "--supports must be from: #{Bali::Widget::SIZES.join(', ')}" if unknown.any?

      validate_default_is_offered
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

    def pattern = options[:pattern]

    def parent_class = "Bali::Widget::#{PATTERNS.fetch(pattern)}"

    # `ValueBase` offers `small` alone, and that is the class's point rather than
    # a limitation of it — a bare figure at `large` is a title, a number and most
    # of a 2x2 cell of whitespace. The base would reject the mismatch itself at
    # class-definition time; refusing here means the message can name the flag.
    def offered_sizes
      Array(options[:supports]).presence || parent_class.constantize.supported_sizes.map(&:to_s)
    end

    def validate_default_is_offered
      return if offered_sizes.include?(options[:size])

      raise Thor::Error,
            "--pattern #{pattern} offers #{offered_sizes.join(', ')}, so --size #{options[:size]} " \
            "is not a size a user could choose. Pick one of those, or pass --supports."
    end

    # Only written when it differs from what the base already offers. A `supports`
    # restating the default is a second place to keep the same fact.
    def supports_declaration
      return if options[:supports].nil?

      "supports #{options[:supports].map { |s| ":#{s}" }.join(', ')}"
    end

    # `LowStockItems` -> `low_stock_items`, the same derivation `Base.key` does.
    def widget_key = file_name

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
        #{'      '}empty: TODO — what to say when there is nothing to show
      YAML
    end
  end
end
