module Bali
  module Navbar
    module Item
      class Component < ApplicationViewComponent
        attr_reader :name, :tag_name, :options

        def initialize(tag_name: :a, name: '', type: :item, **options)
          @tag_name = tag_name
          @name = name
          @options = prepend_class_name(options, "navbar-#{type}")
        end

        def call
          return tag.send(tag_name, name, **options) if content.blank?

          tag.send(tag_name, **options) { content }
        end
      end
    end
  end
end