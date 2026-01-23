# frozen_string_literal: true

module Bali
  module Skeleton
    class Component < ApplicationViewComponent
      # Preset patterns for common skeleton layouts
      VARIANTS = {
        text: :text,           # Single line of text
        paragraph: :paragraph, # Multiple lines of text
        card: :card,           # Card with title and content
        avatar: :avatar,       # Circular avatar
        button: :button,       # Button shape
        modal: :modal,         # Modal content (title + paragraph + actions)
        list: :list            # List of items
      }.freeze

      SIZES = {
        xs: { height: 'h-3', width: 'w-full' },
        sm: { height: 'h-4', width: 'w-full' },
        md: { height: 'h-6', width: 'w-full' },
        lg: { height: 'h-8', width: 'w-full' }
      }.freeze

      def initialize(variant: :text, size: :sm, lines: 3, **options)
        @variant = variant.to_sym
        @size = size.to_sym
        @lines = lines
        @options = options
      end

      def call
        case @variant
        when :text
          render_text
        when :paragraph
          render_paragraph
        when :card
          render_card
        when :avatar
          render_avatar
        when :button
          render_button
        when :modal
          render_modal
        when :list
          render_list
        else
          render_text
        end
      end

      private

      def render_text
        tag.div(class: skeleton_classes(width_class))
      end

      def render_paragraph
        tag.div(class: 'space-y-2') do
          safe_join(
            @lines.times.map do |i|
              # Last line is shorter for natural look
              width = i == @lines - 1 ? 'w-3/4' : 'w-full'
              tag.div(class: skeleton_classes(width))
            end
          )
        end
      end

      def render_card
        tag.div(class: 'space-y-4') do
          safe_join([
            tag.div(class: skeleton_classes('h-6 w-1/3')), # Title
            tag.div(class: 'space-y-2') do
              safe_join([
                tag.div(class: skeleton_classes('h-4 w-full')),
                tag.div(class: skeleton_classes('h-4 w-full')),
                tag.div(class: skeleton_classes('h-4 w-2/3'))
              ])
            end
          ])
        end
      end

      def render_avatar
        size_class = case @size
                     when :xs then 'w-8 h-8'
                     when :sm then 'w-10 h-10'
                     when :md then 'w-12 h-12'
                     when :lg then 'w-16 h-16'
                     else 'w-10 h-10'
                     end
        tag.div(class: skeleton_classes("#{size_class} rounded-full"))
      end

      def render_button
        tag.div(class: skeleton_classes('h-10 w-24 rounded-btn'))
      end

      def render_modal
        tag.div(class: 'space-y-4') do
          safe_join([
            # Title
            tag.div(class: skeleton_classes('h-7 w-1/2')),
            # Content lines
            tag.div(class: 'space-y-2 py-2') do
              safe_join([
                tag.div(class: skeleton_classes('h-4 w-full')),
                tag.div(class: skeleton_classes('h-4 w-full')),
                tag.div(class: skeleton_classes('h-4 w-3/4'))
              ])
            end,
            # Action buttons
            tag.div(class: 'flex justify-end gap-2 pt-4') do
              safe_join([
                tag.div(class: skeleton_classes('h-10 w-20 rounded-btn')),
                tag.div(class: skeleton_classes('h-10 w-24 rounded-btn'))
              ])
            end
          ])
        end
      end

      def render_list
        tag.div(class: 'space-y-3') do
          safe_join(
            @lines.times.map do
              tag.div(class: 'flex items-center gap-3') do
                safe_join([
                  tag.div(class: skeleton_classes('w-10 h-10 rounded-full shrink-0')),
                  tag.div(class: 'flex-1 space-y-2') do
                    safe_join([
                      tag.div(class: skeleton_classes('h-4 w-1/3')),
                      tag.div(class: skeleton_classes('h-3 w-1/2'))
                    ])
                  end
                ])
              end
            end
          )
        end
      end

      def skeleton_classes(*additional)
        class_names('skeleton', height_class, *additional, @options[:class])
      end

      def height_class
        SIZES.dig(@size, :height) || 'h-4'
      end

      def width_class
        @options[:width] || SIZES.dig(@size, :width) || 'w-full'
      end
    end
  end
end
