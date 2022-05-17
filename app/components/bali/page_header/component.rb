# frozen_string_literal: true

module Bali
  module PageHeader
    class Component < ApplicationViewComponent
      def initialize(title:, subtitle: nil, title_class: 'is-1', subtitle_class: 'is-6')
        @title = title
        @subtitle = subtitle
        @title_class = title_class
        @subtitle_class = subtitle_class
      end

      def title_classes
        class_names('title', @title_class)
      end

      def subtitle_classes
        class_names('subtitle mt-0', @subtitle_class)
      end
    end
  end
end
