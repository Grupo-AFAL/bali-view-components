# frozen_string_literal: true

module Bali
  module Columns
    class Component < ApplicationViewComponent
      # Variable gap sizes (used with is-variable class)
      GAPS = {
        0 => 'is-0',
        1 => 'is-1',
        2 => 'is-2',
        3 => 'is-3',
        4 => 'is-4',
        5 => 'is-5',
        6 => 'is-6',
        7 => 'is-7',
        8 => 'is-8'
      }.freeze

      renders_many :columns, Column::Component

      # @param gapless [Boolean] Remove all gaps between columns (Bulma: is-gapless)
      # @param gap [Integer, nil] Variable gap size 0-8 (Bulma: is-variable is-N)
      # @param multiline [Boolean] Allow columns to wrap to multiple lines (Bulma: is-multiline)
      # @param centered [Boolean] Center columns horizontally (Bulma: is-centered)
      # @param vcentered [Boolean] Center columns vertically (Bulma: is-vcentered)
      # @param mobile [Boolean] Keep columns on mobile instead of stacking (Bulma: is-mobile)
      # rubocop:disable Metrics/ParameterLists -- Bulma columns have many modifiers
      def initialize(gapless: false, gap: nil, multiline: false, centered: false,
                     vcentered: false, mobile: false, **options)
        # rubocop:enable Metrics/ParameterLists
        @gapless = gapless
        @gap = gap
        @multiline = multiline
        @centered = centered
        @vcentered = vcentered
        @mobile = mobile
        @options = options
      end

      private

      attr_reader :options

      def container_classes
        class_names(
          'columns',
          { 'is-gapless' => @gapless },
          { 'is-variable' => @gap.present? },
          GAPS[@gap],
          { 'is-multiline' => @multiline },
          { 'is-centered' => @centered },
          { 'is-vcentered' => @vcentered },
          { 'is-mobile' => @mobile },
          options[:class]
        )
      end
    end
  end
end
