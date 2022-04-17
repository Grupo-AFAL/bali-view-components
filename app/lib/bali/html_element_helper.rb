module Bali
  module HtmlElementHelper
    def prepend_action(options, action)
      prepend_data_attribute(options, :action, action)
    end

    def prepend_controller(options, controller_name)
      prepend_data_attribute(options, :controller, controller_name)
    end

    def prepend_class_name(options, class_name)
      options[:class] = "#{class_name} #{options[:class]}".strip
      options
    end

    private

    def prepend_data_attribute(options, attr_name, attr_value)
      options[:data] ||= {}
      options[:data][attr_name] = "#{attr_value} #{options[:data][attr_name]}".strip
      options
    end
  end
end
