# frozen_string_literal: true

module Bali
  module FormPage
    class Component < ApplicationViewComponent
      renders_one :body
      renders_one :sidebar

      def initialize(title:, subtitle: nil, breadcrumbs: [], back: nil, max_width: "max-w-3xl", **options)
        @title = title
        @subtitle = subtitle
        @breadcrumbs = breadcrumbs
        @back = back
        @max_width = max_width
        @options = options
      end

      private

      attr_reader :title, :subtitle, :breadcrumbs, :back, :max_width
    end
  end
end
