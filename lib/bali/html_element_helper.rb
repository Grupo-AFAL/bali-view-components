# frozen_string_literal: true

module Bali
  module HtmlElementHelper
    def prepend_action(options, action)
      prepend_data_attribute(options, :action, action)
    end

    def prepend_controller(options, controller_name)
      prepend_data_attribute(options, :controller, controller_name)
    end

    def prepend_values(options, controller_name, values)
      values.each do |key, value|
        next if value.nil?

        options = prepend_data_attribute(
          options,
          "#{controller_name}-#{hyphenize(key)}-value",
          normalize_data_attribute_value(value)
        )
      end

      options
    end

    def prepend_turbo_method(options, turbo_method)
      prepend_data_attribute(options, :turbo_method, turbo_method)
    end

    def prepend_class_name(options, class_name)
      options[:class] = "#{class_name} #{options[:class]}".strip
      options
    end

    def prepend_style(options, styles)
      options[:style] = "#{styles} #{options[:style]}".strip
      options
    end

    # A copy of `options` that the `prepend_*` family can safely be pointed at.
    #
    # They write to `options[:data][key]` IN PLACE, and every way of copying a
    # hash in Ruby — `dup`, `merge`, `except` — copies the OUTER level only. So a
    # component that prepends onto the options hash a host handed it writes back
    # into the host's hash. Render N of something from one shared hash and the
    # second gets the first's wiring on top of its own:
    # `data-controller="x x"`, two Stimulus instances on one element.
    #
    # SHALLOW ON PURPOSE. Every write in the family lands at depth 2, as a
    # freshly interpolated String (`prepend_values` runs its argument through
    # `normalize_data_attribute_value` first, so even a Hash arrives copied).
    # Nothing writes deeper, so nothing deeper needs severing.
    #
    # Call it ONCE, where the options enter the component, not next to the first
    # `prepend_*`. The point is that everything after it is safe — including a
    # `prepend_*` added later, on a path that has none today.
    def detach_data(options)
      return options unless options.key?(:data)

      options.merge(data: options[:data].dup)
    end

    def prepend_data_attribute(options, attr_name, attr_value)
      options[:data] ||= {}
      options[:data][attr_name] = "#{attr_value} #{options[:data][attr_name]}".strip
      options
    end

    def hyphenize_keys(options)
      options.transform_keys { |k| hyphenize(k) }
    end

    def hyphenize(key)
      key.to_s.gsub("_", "-").to_sym
    end

    private

    def normalize_data_attribute_value(value)
      value.is_a?(Hash) || value.is_a?(Array) ? value.to_json : value
    end
  end
end
