# frozen_string_literal: true

module Bali
  module GanttChart
    module ViewModeButton
      class Component < ApplicationViewComponent
        include Utils::Url

        def initialize(label:, zoom:, active: false, href: nil, **options)
          @label = label
          @zoom = zoom
          @active = active
          @href = href

          @options = prepend_class_name(
            options,
            class_names('button is-small', 'is-selected is-info': @active)
          )
        end

        def call
          tag.a @label, href: href, class: @options[:class]
        end

        private

        def href
          add_query_param(@href.to_s, :zoom, @zoom)
        end
      end
    end
  end
end
