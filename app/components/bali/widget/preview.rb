# frozen_string_literal: true

module Bali
  module Widget
    class Preview < ApplicationViewComponentPreview
      # A widget with no host behind it. Defined here so the preview needs no
      # dummy-app model and no locale fixtures.
      class Demo < Bali::Widget::Base
        sized :medium

        def self.title = "Low stock items"
        def self.short_title = "Low stock"
        def self.empty_message = "Nothing running low"

        def initialize(count:, failed:)
          @count = count
          @failed = failed
          super(nil)
        end

        def call
          return Bali::Widget::Result.failed if @failed

          Bali::Widget::Result.new(
            count: @count,
            view_all_path: "/lookbook",
            items: Array.new(@count) do |i|
              Bali::Widget::Row.new(title: "Ingredient #{i + 1}",
                                     subtitle: Bali::Widget.subtitle("#{i + 1} left", "Cocina"),
                                     href: "/lookbook")
            end
          )
        end
      end

      # A dashboard card. `size` changes the design, not just the width: `small`
      # drops the list for a single stat, and `large` is `medium`'s width at
      # double height.
      #
      # Toggle `editing` to see the edit chrome — a handle, a remove button and
      # the size picker — which the card always renders and CSS hides.
      #
      # @param size select { choices: [small, medium, large, wide] }
      # @param count number
      # @param failed toggle
      # @param editing toggle
      def default(size: :medium, count: 5, failed: false, editing: false)
        render_with_template(locals: {
                                widget: Demo.new(count: count.to_i, failed: failed)
                                            .with_size(size),
                                editing: editing
                              })
      end
    end
  end
end
