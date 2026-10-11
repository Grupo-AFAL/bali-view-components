# frozen_string_literal: true

module Bali
  module Legend
    class Preview < ApplicationViewComponentPreview
      # The key to a colour code: a marker, an optional icon and a label per
      # colour, wrapping in a row. The list is named by the title, or by
      # `aria_label:` when there is none; markers and icons are hidden from
      # assistive tech, so each entry reads as its label.
      #
      # @param title text
      # @param marker select { choices: [dot, swatch] }
      # @param icons toggle
      # @param descriptions toggle
      def default(title: "States", marker: :dot, icons: true, descriptions: true)
        render Bali::Legend::Component.new(title: title.presence, aria_label: "States") do |legend|
          Bali::Legend::Preview::STATES.each do |state|
            legend.with_item(label: state[:label], color: state[:color], marker: marker.to_sym,
                             icon: (state[:icon] if icons),
                             description: (state[:description] if descriptions))
          end
        end
      end

      # Hex colours through `custom_color:`, for a code that does not follow the
      # theme — here, the pins of a map that paints with the same hex. No title,
      # so `aria_label:` names the list.
      def custom_colors
        render Bali::Legend::Component.new(aria_label: "Location types") do |legend|
          legend.with_item(label: "Commercial", custom_color: "#2563EB")
          legend.with_item(label: "Industrial", custom_color: "#D97706")
          legend.with_item(label: "Office", custom_color: "#7C3AED", icon: "building")
          legend.with_item(label: "Residential", custom_color: "#059669")
          legend.with_item(label: "Other", custom_color: "#6B7280")
        end
      end

      # `marker: :swatch` is a tinted square with a stronger border, for a
      # colour the page paints as a tint — a table row, a calendar cell.
      def swatches
        render Bali::Legend::Component.new(title: "Rows") do |legend|
          legend.with_item(label: "President", color: :primary, marker: :swatch)
          legend.with_item(label: "Secretary", color: :secondary, marker: :swatch)
          legend.with_item(label: "Titular board member", color: :warning, marker: :swatch)
        end
      end

      STATES = [
        { label: "Draft", color: :ghost, icon: "file-pen", description: "Being written; not yet submitted." },
        { label: "In review", color: :info, icon: "refresh-cw", description: "Submitted and awaiting approval." },
        { label: "Under construction", color: :warning, icon: "traffic-cone",
          description: "Approved to be built; not yet in force." },
        { label: "Under remodeling", color: :secondary, icon: "wrench",
          description: "In force, with a new version being prepared." },
        { label: "Current", color: :success, icon: "circle-check", description: "Approved and in force." },
        { label: "Obsolete", color: :neutral, icon: "archive", description: "Replaced by a later version." },
        { label: "Rejected", color: :error, icon: "circle-x", description: "Returned without approval." },
        { label: "Accent", color: :accent, icon: "sparkles", description: "The theme's accent colour." },
        { label: "Primary", color: :primary, icon: "star", description: "The theme's primary colour." }
      ].freeze
    end
  end
end
