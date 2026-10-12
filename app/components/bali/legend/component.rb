# frozen_string_literal: true

module Bali
  module Legend
    # The key to a colour code: one entry per colour a listing or a map paints
    # with, each a dot, an optional icon and a label, wrapping in a row. The card
    # around it, if any, belongs to the host.
    #
    # @example States of a catalog
    #   render Bali::Legend::Component.new(title: t('.states')) do |legend|
    #     legend.with_item(label: t('.current'), color: :success, icon: 'circle-check',
    #                      description: t('.current_help'))
    #     legend.with_item(label: t('.draft'), color: :ghost, icon: 'file-pen')
    #   end
    #
    # @example Map markers painted with a hex
    #   render Bali::Legend::Component.new(aria_label: t('.location_types')) do |legend|
    #     legend.with_item(label: t('.office'), custom_color: '#7C3AED')
    #   end
    class Component < ApplicationViewComponent
      BASE_CLASSES = "legend-component"

      renders_many :items, Legend::Item::Component

      # @param title [String, nil] Shown before the entries, and the list's accessible name
      # @param aria_label [String, nil] The list's accessible name when there is no title.
      #   Defaults to `bali_view.legend.label`.
      # @param options [Hash] HTML attributes for the root element
      def initialize(title: nil, aria_label: nil, **options)
        @title = title
        @aria_label = aria_label
        @id = options[:id] || "legend-#{SecureRandom.hex(4)}"
        @options = prepend_class_name(options, BASE_CLASSES)
      end

      private

      attr_reader :title, :options

      def title_id
        "#{@id}-title"
      end

      def list_name
        return { "aria-labelledby": title_id } if title.present?

        { "aria-label": @aria_label.presence || t(".label") }
      end
    end
  end
end
