# frozen_string_literal: true

module Bali
  module Footer
    class Component < ApplicationViewComponent
      COLORS = {
        neutral: "bg-neutral text-neutral-content",
        base: "bg-base-200 text-base-content",
        primary: "bg-primary text-primary-content",
        secondary: "bg-secondary text-secondary-content"
      }.freeze

      renders_one :brand, ->(name: nil, description: nil, &block) {
        BrandComponent.new(name: name, description: description, &block)
      }

      renders_many :sections, ->(**options, &block) {
        SectionComponent.new(**options, &block)
      }

      renders_one :bottom, ->(&block) {
        classes = "border-t border-current/20 mt-8 pt-8 text-sm text-center"
        tag.div(class: classes, &block)
      }

      attr_reader :html_options

      # @param color [Symbol] Background color preset (:neutral, :base, :primary, :secondary)
      # @param center [Boolean] Center-align footer content
      def initialize(color: :neutral, center: false, **html_options)
        @color = color
        @center = center
        @html_options = prepend_class_name(html_options, component_classes)
      end

      def center?
        @center
      end

      private

      # daisyUI's `.footer-center` alone is `grid-auto-flow: column dense`, every section side by
      # side below 640px; only `.footer-horizontal.footer-center` stacks them.
      def layout_classes
        center? ? "footer footer-horizontal footer-center" : "footer sm:footer-horizontal"
      end

      def component_classes
        [
          "footer-component p-10",
          COLORS[@color]
        ].compact.join(" ")
      end

      # Brand section component
      class BrandComponent < ApplicationViewComponent
        attr_reader :name, :description

        def initialize(name: nil, description: nil, &block)
          @name = name
          @description = description
          @block = block
        end

        def call
          tag.aside do
            if @block
              capture(&@block)
            else
              safe_join([
                (tag.h3(name, class: "text-lg font-bold mb-2") if name),
                (tag.p(description, class: "text-sm max-w-xs") if description)
              ].compact)
            end
          end
        end
      end

      # Footer section with title and links
      class SectionComponent < ApplicationViewComponent
        # Nothing in the footer is muted. daisyUI paints `.footer-title` at `opacity: .6` from
        # @layer utilities, which read 2.83:1 on `afal` over `primary` (AA wants 4.5). An opacity
        # passes there only from `.9` up, 4.55 against 5.25 in full: a muting nobody sees.
        TITLE_CLASSES = "footer-title opacity-100"

        renders_many :links, ->(name:, href:, **options) {
          tag.a(name, href: href, class: "link link-hover", **options)
        }

        attr_reader :title

        def initialize(title: nil, **options)
          @title = title
          @options = options
        end

        def call
          tag.nav(**@options) do
            safe_join([
              (tag.h6(title, class: TITLE_CLASSES) if title),
              *links
            ].compact)
          end
        end
      end
    end
  end
end
