# frozen_string_literal: true

module Bali
  module Filters
    module Option
      class Component < ApplicationViewComponent
        attr_reader :title, :name, :value, :selected

        def initialize(title:, name:, value:, selected: false)
          @title = title
          @name = name
          @value = value
          @selected = selected
        end

        def classes
          class_names('tag', 'is-selected': selected)
        end

        def input_id
          "#{name.gsub(/[\[\]]+/, '_').gsub(/-+/, '_')}_#{value}"
        end
      end
    end
  end
end
