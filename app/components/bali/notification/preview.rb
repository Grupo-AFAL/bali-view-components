# frozen_string_literals: true

module Bali
  module Notification
    class Preview < ApplicationViewComponentPreview
      def default
        render Notification::Component.new(type: :primary, miliseconds_to_close: 10000 ) do
          tag.h1 'This is a alert notification'
        end
        render Notification::Component.new(type: :link, miliseconds_to_close: 10000 ) do
          tag.h1 'This is a alert notification'
        end
        render Notification::Component.new(type: :danger, miliseconds_to_close: 10000 ) do
          tag.h1 'This is a alert notification'
        end
        render Notification::Component.new(type: :success, miliseconds_to_close: 10000 ) do
          tag.h1 'This is a alert notification'
        end
        render Notification::Component.new(type: :info, miliseconds_to_close: 10000 ) do
          tag.h1 'This is a alert notification'
        end
      end
    end
  end
end