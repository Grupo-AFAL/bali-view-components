# frozen_string_literal: true

module Bali
  module Widget
    class Preview < ApplicationViewComponentPreview
      # One specimen per pattern, with no host behind them — so the preview needs
      # no dummy-app model and no locale fixtures. THE PATTERN IS THE TYPE, so
      # there is a class per ladder rather than one class with a flag.
      # A per-INSTANCE row count. Not a `class_attribute`: Lookbook renders these
      # per request, and a class-level write is process-wide state that two
      # concurrent previews with different `count` params race on, and that leaks
      # into the next request.
      module Sized
        def initialize(rows = 5)
          @rows = rows
          super(nil)
        end

        attr_reader :rows
      end

      class DemoList < Bali::Widget::ListBase
        include Sized
        title "Low stock items"
        short_title "Low stock"
        empty_message "Nothing running low"


        list { FakeScope.new(rows) }
        row do |r|
          r.title { |item| item[:title] }
          r.subtitle { |item| item[:subtitle] }
          r.href "/lookbook"
        end
        view_all_path { "/lookbook" }

        def count = rows



        # A stand-in for a relation: the card only ever asks a scope to count and
        # to hand back a capped preview, so a preview does not need a table.
        FakeScope = Struct.new(:size) do
          def count = size
          def order(*) = self
          def limit(n) = Array.new([ size, n ].min) do |i|
            { title: "Ingredient #{i + 1}", subtitle: Bali::Widget.join("#{i + 1} left", "Cocina") }
          end
        end
      end

      class DemoTrend < Bali::Widget::TrendBase
        include Sized
        title "Low stock items"
        short_title "Low stock"
        empty_message "Nothing running low"


        # Running low on MORE things is worse news, so a rising count reads red.
        positive_when :down
        period_label "vs last week"
        series_labels { %w[Mon Tue Wed Thu Fri Sat Sun] }
        series_values { [ 3, 5, 4, 8, 6, 9, 12 ] }
        view_all_path { "/lookbook" }

        def current = rows

        def previous = [ (rows / 2), 1 ].max
      end

      class DemoProgress < Bali::Widget::ProgressBase
        include Sized
        title "Low stock items"
        short_title "Low stock"
        empty_message "Nothing running low"


        goal_label "of 10"
        series_labels { %w[Mon Tue Wed Thu Fri Sat Sun] }
        series_values { [ 2, 4, 3, 6, 5, 7, 9 ] }
        view_all_path { "/lookbook" }

        def value = rows

        def max = 10
      end

      class DemoValue < Bali::Widget::ValueBase
        include Sized
        title "Production budget"
        short_title "Budget"


        view_all_path { "/lookbook" }

        def value = rows * 421_000_000

        def formatted_value = "$#{Bali::Widget.abbreviate(value)}"
      end

      # DECLARES the failure rather than raising to produce it, for the same
      # reason `DemoWidgets::UnavailableFeed` does: `Base#failed?` probes with
      # `count`, so a widget that really raised would surface it here — and
      # `raise_load_errors?` is true in development, which would take the preview
      # down instead of showing the tile it exists to show. The probe itself is
      # covered in `test/bali/components/widget_test.rb`, where the environment
      # can be stubbed.
      class DemoFailed < Bali::Widget::ValueBase
        title "Low stock items"
        short_title "Low stock"
        supports(*Bali::Widget::SIZES)

        def value = 0

        def failed? = true
      end

      # Keyed by the base each one demonstrates, so the picker and the class
      # names are the same four words.
      PATTERNS = {
        value: DemoValue, list: DemoList, trend: DemoTrend, progress: DemoProgress
      }.freeze

      # A dashboard card. `size` changes the DESIGN, not just the width — the
      # card shows the same fact at every size and gives it more context as it
      # grows, rather than changing subject.
      #
      #   small  the fact alone; the whole tile is one link
      #   medium the fact, and a sparkline beside it
      #   large  the fact, a chart with axes, and the breakdown below
      #
      # `pattern` picks the widget's BASE CLASS: `ValueBase`, `ListBase`,
      # `TrendBase` or `ProgressBase`. A widget is exactly one of them, and
      # `ValueBase` offers `small` alone — pick a bigger size with it and the
      # card falls back, which is `with_size`'s documented behaviour.
      #
      # Toggle `editing` to see the edit chrome — a handle, a remove button and
      # the size picker — which the card always renders and CSS hides.
      #
      # @param size select { choices: [small, medium, large] }
      # @param pattern select { choices: [value, list, trend, progress] }
      # @param count number
      # @param failed toggle
      # @param editing toggle
      def default(size: :medium, pattern: :trend, count: 5, failed: false, editing: false)
        klass = failed ? DemoFailed : Bali::Widget::Preview::PATTERNS.fetch(pattern.to_sym)
        specimen = klass.include?(Sized) ? klass.new(count.to_i) : klass.new

        render_with_template(locals: { widget: specimen.with_size(size.to_sym), editing: editing })
      end
    end
  end
end
