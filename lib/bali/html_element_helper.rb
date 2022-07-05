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
          value.to_json
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

    def prepend_data_attribute(options, attr_name, attr_value)
      options[:data] ||= {}
      options[:data][attr_name] = "#{attr_value} #{options[:data][attr_name]}".strip
      options
    end

    def hyphenize_keys(options)
      options.transform_keys { |k| hyphenize(k) }
    end

    def hyphenize(key)
      key.to_s.gsub('_', '-').to_sym
    end
  end
end
