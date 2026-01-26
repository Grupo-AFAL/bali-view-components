# frozen_string_literal: true

module Bali
  module Timeline
    class Preview < ApplicationViewComponentPreview
      # Basic Timeline
      # -----------------
      # Timeline displays a chronological sequence of events using DaisyUI's
      # native timeline component with semantic HTML structure.
      #
      # @param position select [left, center, right]
      def default(position: :left)
        render Bali::Timeline::Component.new(position: position) do |c|
          c.with_tag_header(text: 'Start')
          c.with_tag_item(heading: 'January 2022') { tag.p 'Timeline event 1' }
          c.with_tag_item(heading: 'February 2022') { tag.p 'Timeline event 2' }
          c.with_tag_header(text: 'Milestone')
          c.with_tag_item(heading: 'March 2022') { tag.p 'Timeline event 3' }
          c.with_tag_item(heading: 'April 2022') { tag.p 'Timeline event 4' }
          c.with_tag_header(text: 'End')
        end
      end

      # Timeline with Icons
      # ---------------------
      # Each timeline item can display a Lucide icon in the marker.
      # Use `icon: 'icon-name'` to specify the icon.
      #
      # @param position select [left, center, right]
      def with_icons(position: :left)
        render Bali::Timeline::Component.new(position: position) do |c|
          c.with_tag_header(text: 'Start')
          c.with_tag_item(heading: 'Alert', icon: 'triangle-alert') { tag.p 'Warning event' }
          c.with_tag_item(heading: 'Notification', icon: 'bell') { tag.p 'Bell rang' }
          c.with_tag_item(heading: 'Completed', icon: 'check') { tag.p 'Task done' }
          c.with_tag_item(heading: 'Media', icon: 'image') { tag.p 'Image uploaded' }
          c.with_tag_header(text: 'End')
        end
      end

      # Color Variants
      # ----------------
      # Timeline items and headers support color variants for visual hierarchy.
      # Use `color:` param on items and headers.
      def with_colors
        render Bali::Timeline::Component.new do |c|
          c.with_tag_header(text: 'Project Start', color: :primary)
          c.with_tag_item(heading: 'Created', icon: 'plus', color: :primary) do
            tag.p 'Project initialized'
          end
          c.with_tag_item(heading: 'In Progress', icon: 'loader', color: :info) do
            tag.p 'Development underway'
          end
          c.with_tag_item(heading: 'Warning', icon: 'triangle-alert', color: :warning) do
            tag.p 'Deadline approaching'
          end
          c.with_tag_item(heading: 'Issue', icon: 'x', color: :error) do
            tag.p 'Bug discovered'
          end
          c.with_tag_item(heading: 'Completed', icon: 'check', color: :success) do
            tag.p 'Project delivered'
          end
          c.with_tag_header(text: 'Complete', color: :success)
        end
      end

      # Custom Header Styles
      # ----------------------
      # Headers use DaisyUI badge colors. Use `color:` for semantic colors
      # or `tag_class:` for custom badge classes (legacy support).
      def custom_header_styles
        render Bali::Timeline::Component.new do |c|
          c.with_tag_header(text: 'Primary', color: :primary)
          c.with_tag_item(heading: 'Event 1') { tag.p 'Content' }
          c.with_tag_header(text: 'Secondary', color: :secondary)
          c.with_tag_item(heading: 'Event 2') { tag.p 'Content' }
          c.with_tag_header(text: 'Outline (legacy)', tag_class: 'badge-outline badge-primary')
          c.with_tag_item(heading: 'Event 3') { tag.p 'Content' }
          c.with_tag_header(text: 'Ghost', color: :ghost)
        end
      end
    end
  end
end
