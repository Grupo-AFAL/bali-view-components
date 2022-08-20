# frozen_string_literal: true

module Bali
  module GanttChart
    module ViewModeButton
      class Component < ApplicationViewComponent
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
          zoom_param = "?zoom=#{@zoom}"

          @href.nil? ? zoom_param : @href + zoom_param
        end
      end
    end
  end
end
