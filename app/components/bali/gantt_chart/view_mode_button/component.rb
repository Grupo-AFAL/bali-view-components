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

          @options = options
        end

        def call
          tag.a @label, href: href, class: button_classes
        end

        private

        def href
          add_query_param(@href.to_s, :zoom, @zoom)
        end

        def button_classes
          class_names(
            'btn btn-sm join-item',
            @options[:class],
            'btn-info' => @active,
            'btn-ghost' => !@active
          )
        end
      end
    end
  end
end
