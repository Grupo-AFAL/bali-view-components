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

        def initialize(count:, failed:, pattern: :list)
          @count = count
          @failed = failed
          @pattern = pattern.to_sym
          super(nil)
        end

        # One widget, three ladders — the same fact dressed three ways, which is
        # the whole point: `pattern` changes what CONTEXT the card can show, not
        # what the card is about.
        def call
          return Bali::Widget::Result.failed if @failed

          Bali::Widget::Result.new(
            count: @count,
            view_all_path: "/lookbook",
            items: Array.new(@count) do |i|
              Bali::Widget::Row.new(title: "Ingredient #{i + 1}",
                                     subtitle: Bali::Widget.subtitle("#{i + 1} left", "Cocina"),
                                     href: "/lookbook")
            end,
            **ladder
          )
        end

        private

        def ladder
          case @pattern
          # Number -> number + trend -> number + trend + breakdown. `positive_when:
          # :down` because running low on more things is worse news, so a rising
          # count here has to read red.
          when :metric
            { trend: Bali::Widget::Trend.new(delta: 12, period: "vs last week",
                                             positive_when: :down),
              series: Bali::Widget::Series.new(values: [ 3, 5, 4, 8, 6, 9, 12 ],
                                               labels: %w[Mon Tue Wed Thu Fri Sat Sun]) }
          # Ring -> ring + history.
          when :gauge
            { gauge: Bali::Widget::Gauge.new(value: @count, max: 10, label: "of 10"),
              series: Bali::Widget::Series.new(values: [ 2, 4, 3, 6, 5, 7, @count ],
                                               labels: %w[Mon Tue Wed Thu Fri Sat Sun],
                                               type: :bar) }
          # Item -> list of items. The original contract, with none of the
          # ladder fields set — which is exactly what every widget written
          # before the ladder looks like.
          else
            {}
          end
        end
      end

      # A dashboard card. `size` changes the DESIGN, not just the width — the
      # card shows the same fact at every size and gives it more context as it
      # grows, rather than changing subject.
      #
      #   small  the fact alone; the whole tile is one link
      #   medium the fact, and a sparkline beside it
      #   large  the fact, a chart with axes, and the breakdown below
      #   wide   two columns: the fact and its chart, then the breakdown
      #
      # `pattern` switches between the three ladders. `list` sets none of the
      # ladder fields, which is what every widget written against the original
      # contract looks like — it still renders at every size, with the context
      # region simply absent.
      #
      # Toggle `editing` to see the edit chrome — a handle, a remove button and
      # the size picker — which the card always renders and CSS hides.
      #
      # @param size select { choices: [small, medium, large, wide] }
      # @param pattern select { choices: [metric, list, gauge] }
      # @param count number
      # @param failed toggle
      # @param editing toggle
      def default(size: :medium, pattern: :metric, count: 5, failed: false, editing: false)
        render_with_template(locals: {
                                widget: Demo.new(count: count.to_i, failed: failed,
                                                 pattern: pattern)
                                            .with_size(size),
                                editing: editing
                              })
      end
    end
  end
end
