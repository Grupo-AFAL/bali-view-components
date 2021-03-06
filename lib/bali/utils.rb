# frozen_string_literal: true

module Bali
  module Utils
    def class_names(names, conditional_names = {})
      if names.is_a?(Hash)
        conditional_names = names
        classes = []
      else
        classes = Array(names)
      end

      conditional_names.each do |key, condition|
        classes.push(key) if condition
      end
      classes.join(' ').strip
    end

    def custom_dom_id(model)
      "#{model.class.name.tableize.singularize.gsub('/', '_')}_#{model.id}"
    end

    def test_id_attr(params)
      return unless params

      test_id = case params
                when ActiveRecord::Base
                  custom_dom_id(params)
                when String
                  params
                end

      "test-id=\"#{test_id}\"".html_safe
    end

    # The last module parent is always "Object", which means the one before to last
    # is the actual module/namespace we want. Like "INV", "Cafeteria" or "EK"
    def app_module
      controller.class.module_parents[-2]
    end
  end
end
