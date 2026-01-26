# frozen_string_literal: true

module Bali
  module Navbar
    module Item
      class Component < ApplicationViewComponent
        DEFAULT_TAG = :a

        def initialize(tag_name: DEFAULT_TAG, name: '', **options)
          @tag_name = tag_name
          @name = name
          @options = options
        end

        def call
          return tag.send(@tag_name, @name, **@options) if content.blank?

          tag.send(@tag_name, **@options) { content }
        end

        private

        attr_reader :name, :tag_name, :options
      end
    end
  end
end
