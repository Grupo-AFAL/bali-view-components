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

    # A copy of `options` the `prepend_*` family can safely be pointed at. They
    # write to `options[:data][key]` in place, and `dup`, `merge` and `except`
    # all copy the OUTER level only — so a component prepending onto the hash a
    # host handed it writes back into the host's hash.
    #
    # Shallow on purpose: every write in the family lands at depth 2 as a freshly
    # interpolated String.
    #
    # Call it where the options ENTER the component, not next to the first
    # `prepend_*`, so a `prepend_*` added later is safe too.
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
