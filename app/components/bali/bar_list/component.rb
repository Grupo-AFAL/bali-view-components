# frozen_string_literal: true

module Bali
  module BarList
    # Horizontal bars written as HTML: one row per item, its label with the figure at the end of
    # the line, and a track under them filled in proportion to the largest value. A row with
    # `href:` is one link, label and figure together.
    #
    # @example People at a restaurant by job profile
    #   render Bali::BarList::Component.new(
    #     aria_label: t('.by_job_profile'),
    #     items: staff.map { |row| { label: row.name, value: row.people, href: job_profile_path(row.job_profile) } }
    #   )
    class Component < ApplicationViewComponent
      BASE_CLASSES = "bar-list"

      Item = Data.define(:label, :value, :href, :color, :id) do
        def initialize(label:, value:, href: nil, color: nil, id: nil)
          unless value.is_a?(Numeric)
            raise ArgumentError, "Bali::BarList::Component: #{label.inspect} has value #{value.inspect}, not a number."
          end

          super(label:, value:, href:, color: Bali::Color.name!(Bali::BarList::Component, color), id:)
        end
      end
      private_constant :Item

      # @param items [Array<Hash>] One hash per row: `label:` and a Numeric `value:` are required;
      #   `href:` makes the row a link, `color:` overrides the list's, `id:` lands on the row's
      #   `<li>`. Any other key raises.
      # @param color [Symbol] Colour of the bars (Bali::Color::NAMES). `:neutral` and `:ghost`
      #   paint base-content, which is daisyUI's own `.progress`.
      # @param format [#call, nil] Turns a value into the figure's text. Defaults to Bali::Figure:
      #   a thousands comma and a decimal point, whatever the locale.
      # @param aria_label [String, nil] The list's accessible name
      # @param options [Hash] HTML attributes for the `<ul>`
      def initialize(items:, color: :primary, format: nil, aria_label: nil, **options)
        @items = items.map { |item| Item.new(**item) }
        @max = @items.map(&:value).max
        @color = Bali::Color.name!(self.class, color)
        @format = format || Bali::Figure.method(:delimited)
        @options = prepend_class_name(options, BASE_CLASSES).merge(role: "list", "aria-label": aria_label)
      end

      def render? = @items.any?

      private

      def value_text(value) = @format.call(value)
    end
  end
end
