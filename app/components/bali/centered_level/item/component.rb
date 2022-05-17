# frozen_string_literal: true

module Bali
  module CenteredLevel
    module Item
      class Component < ApplicationViewComponent
        attr_reader :heading, :title, :title_class, :heading_class

        def initialize(heading:, title:, options: {})
          @heading = heading
          @title = title
          @title_class = options.delete(:title_class)
          @heading_class = options.delete(:heading_class)
          @options = options.transform_keys { |k| k.to_s.gsub('_', '-') }
        end

        def title_classes
          title_class || 'title is-3'
        end

        def title_items
          return safe_join(title.map { |t| tag.p(t, class: title_classes) }) if title.is_a?(Array)

          tag.p(title, class: title_classes)
        end

        def call
          safe_join([
                      tag.p(heading, class: "heading #{heading_class}"), title_items
                    ])
        end
      end
    end
  end
end
