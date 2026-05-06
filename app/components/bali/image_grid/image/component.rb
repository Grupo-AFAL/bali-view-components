# frozen_string_literal: true

module Bali
  module ImageGrid
    module Image
      class Component < ApplicationViewComponent
        ASPECT_RATIOS = {
          square: "aspect-square",
          video: "aspect-video",
          '3/2': "aspect-[3/2]",
          '4/3': "aspect-[4/3]",
          '4/5': "aspect-[4/5]",
          '16/9': "aspect-[16/9]"
        }.freeze

        renders_one :footer, FooterComponent

        def initialize(aspect_ratio: :'3/2', expandable: false, full_src: nil, **options)
          @aspect_ratio = aspect_ratio.to_sym
          @expandable = expandable
          @full_src = full_src
          @options = options
        end

        private

        attr_reader :options, :expandable, :full_src

        def aspect_class
          ASPECT_RATIOS[@aspect_ratio] || "aspect-#{@aspect_ratio}"
        end

        def figure_classes
          class_names(
            aspect_class,
            "overflow-hidden",
            "[&_img]:w-full [&_img]:h-full [&_img]:object-cover",
            footer? ? "rounded-t-2xl" : "rounded-2xl"
          )
        end

        def card_classes
          class_names("card", "bg-base-100", options[:class])
        end

        def card_attributes
          options.except(:class)
        end

        def expand_label
          I18n.t("bali.image_grid.expand", default: "Expand image")
        end

        def expand_button_classes
          class_names(
            figure_classes,
            "block w-full p-0 cursor-zoom-in",
            "focus:outline-none focus-visible:ring-2 focus-visible:ring-primary"
          )
        end

        def expand_button_data
          { controller: "image-expander", action: "click->image-expander#open" }.tap do |data|
            data[:image_expander_src_value] = full_src if full_src
          end
        end
      end
    end
  end
end
