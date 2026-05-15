# frozen_string_literal: true

module Bali
  module ImageGrid
    module Image
      class FooterComponent < ApplicationViewComponent
        def initialize(**options)
          @options = options
        end

        def call
          tag.div(**footer_options) { content }
        end

        private

        attr_reader :options

        def footer_options
          options.merge(class: class_names("card-body", "p-3", options[:class]))
        end
      end
    end
  end
end
