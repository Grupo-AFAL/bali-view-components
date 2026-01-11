# frozen_string_literal: true

module Bali
  module Card
    module Image
      class Component < ApplicationViewComponent
        attr_reader :src, :options

        def initialize(src:, **options)
          @src = src
          @href = options.delete(:href)
          @options = options
        end

        def wrapper_tag
          @href.present? ? :a : :figure
        end

        def wrapper_options
          return { href: @href } if @href.present?

          {}
        end
      end
    end
  end
end
