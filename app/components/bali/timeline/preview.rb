# frozen_string_literal: true

module Bali
  module Timeline
    class Preview < ApplicationViewComponentPreview
      # Basic Timeline
      # -----------------
      # Timeline displays a chronological sequence of events using DaisyUI's
      # native timeline component with semantic HTML structure.
      #
      # Each entry renders exactly once. With `position: :center` the side is
      # decided in Ruby and alternates across items, so a header in the middle
      # does not flip the alternation.
      #
      # @param position select [left, center, right]
      def default(position: :left)
        render Bali::Timeline::Component.new(position: position) do |c|
          c.with_header(text: 'Start')
          c.with_item(heading: 'January 2022') { tag.p 'Timeline event 1' }
          c.with_item(heading: 'February 2022') { tag.p 'Timeline event 2' }
          c.with_header(text: 'Milestone')
          c.with_item(heading: 'March 2022') { tag.p 'Timeline event 3' }
          c.with_item(heading: 'April 2022') { tag.p 'Timeline event 4' }
          c.with_header(text: 'End')
        end
      end

      # Alternating Sides
      # -------------------
      # `position: :center` alternates items between both sides of the line.
      # Six items with no headers in between, to read the alternation directly.
      def alternating
        render Bali::Timeline::Component.new(position: :center) do |c|
          c.with_item(heading: 'January 2022', icon: 'plus') { tag.p 'Timeline event 1' }
          c.with_item(heading: 'February 2022', icon: 'bell') { tag.p 'Timeline event 2' }
          c.with_item(heading: 'March 2022', icon: 'check') { tag.p 'Timeline event 3' }
          c.with_item(heading: 'April 2022', icon: 'image') { tag.p 'Timeline event 4' }
          c.with_item(heading: 'May 2022', icon: 'loader') { tag.p 'Timeline event 5' }
          c.with_item(heading: 'June 2022', icon: 'x') { tag.p 'Timeline event 6' }
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
          c.with_header(text: 'Start')
          c.with_item(heading: 'Alert', icon: 'triangle-alert') { tag.p 'Warning event' }
          c.with_item(heading: 'Notification', icon: 'bell') { tag.p 'Bell rang' }
          c.with_item(heading: 'Completed', icon: 'check') { tag.p 'Task done' }
          c.with_item(heading: 'Media', icon: 'image') { tag.p 'Image uploaded' }
          c.with_header(text: 'End')
        end
      end

      # Color Variants
      # ----------------
      # Timeline items and headers support color variants for visual hierarchy.
      # `color:` takes a DaisyUI name and follows the theme; `custom_color:` takes
      # a hex and does not. `:ghost` — the default — leaves the marker and the
      # line their DaisyUI colour.
      def with_colors
        render Bali::Timeline::Component.new do |c|
          c.with_header(text: 'Project Start', color: :primary)
          c.with_item(heading: 'Brand event', icon: 'sparkles', custom_color: '#7c3aed') do
            tag.p 'custom_color: the hex escape hatch, on the marker and the line'
          end
          c.with_item(heading: 'Created', icon: 'plus', color: :primary) do
            tag.p 'Project initialized'
          end
          c.with_item(heading: 'In Progress', icon: 'loader', color: :info) do
            tag.p 'Development underway'
          end
          c.with_item(heading: 'Warning', icon: 'triangle-alert', color: :warning) do
            tag.p 'Deadline approaching'
          end
          c.with_item(heading: 'Issue', icon: 'x', color: :error) do
            tag.p 'Bug discovered'
          end
          c.with_item(heading: 'Completed', icon: 'check', color: :success) do
            tag.p 'Project delivered'
          end
          c.with_header(text: 'Complete', color: :success)
        end
      end

      # States
      # --------
      # `state:` is sugar over `icon:`/`color:` for tracking timelines:
      # `:done` renders a `circle-check` primary marker, `:current` a
      # `circle-dot` primary marker, and `:pending` the plain circle with a
      # muted heading. Explicit `icon:`/`color:` win over the state's defaults —
      # `color: :success` turns the check green.
      #
      # The line below each item takes the colour of the item that follows, so
      # the coloured line runs exactly as far as the journey has.
      #
      # `timestamp:` renders on the free side of the line (a string, or anything
      # `l`-localizable), and `href:` turns the content box into a link.
      #
      # @param position select [left, center, right]
      def states(position: :left)
        render Bali::Timeline::Component.new(position: position) do |c|
          c.with_item(state: :done, heading: 'Order placed', timestamp: 'Jul 28, 09:14')
          c.with_item(state: :done, heading: 'Payment confirmed', timestamp: 'Jul 28, 09:20')
          c.with_item(state: :current, heading: 'In transit', timestamp: 'Jul 29, 08:40',
                      href: '/lookbook') do
            tag.p 'Estimated arrival: tomorrow'
          end
          c.with_item(state: :pending, heading: 'Customs')
          c.with_item(state: :done, heading: 'Delivered (explicit green)', color: :success,
                      timestamp: 'Jul 30, 13:05')
        end
      end

      # Tracking preset
      # -----------------
      # The custody-chain / itinerary look: `compact: true` collapses the
      # timeline to a single column, every box lands on the end side, and the
      # timestamp becomes a muted line inside the box — event, date and author
      # in one glance. An `href:` makes an entry clickable (hover feedback
      # included); a `with_timestamp` block replaces the keyword when the
      # metadata needs markup.
      def tracking
        render Bali::Timeline::Component.new(compact: true) do |c|
          c.with_item(state: :done, heading: 'Package received',
                      timestamp: 'Jul 28, 09:14 · A. García')
          c.with_item(state: :done, heading: 'Left warehouse',
                      timestamp: 'Jul 28, 11:02 · R. Ortiz')
          c.with_item(state: :current, heading: 'In transit', href: '/lookbook') do |item|
            item.with_timestamp do
              safe_join([tag.time('Jul 29, 08:40', datetime: '2026-07-29T08:40'), ' · Unit 12'])
            end
          end
          c.with_item(state: :pending, heading: 'Customs')
          c.with_item(state: :pending, heading: 'Delivered')
        end
      end

      # Custom Header Styles
      # ----------------------
      # Headers use DaisyUI badge colors. Use `color:` for the semantic variant
      # and `class:` for anything on top of it, such as `badge-outline`.
      def custom_header_styles
        render Bali::Timeline::Component.new do |c|
          c.with_header(text: 'Primary', color: :primary)
          c.with_item(heading: 'Event 1') { tag.p 'Content' }
          c.with_header(text: 'Secondary', color: :secondary)
          c.with_item(heading: 'Event 2') { tag.p 'Content' }
          c.with_header(text: 'Outline', color: :primary, class: 'badge-outline')
          c.with_item(heading: 'Event 3') { tag.p 'Content' }
          c.with_header(text: 'Ghost', color: :ghost)
        end
      end
    end
  end
end
