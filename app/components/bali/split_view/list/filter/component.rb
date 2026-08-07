# frozen_string_literal: true

module Bali
  module SplitView
    module List
      module Filter
        # One filter pill in a SplitView listing's filter band.
        #
        # It is a **link**, not a form control. Clicking it is an ordinary GET to
        # the URL the caller gave it, which is what makes the rest of the listing
        # behave without a line of code: the server renders page one, so the
        # infinite scroll resets, and the filter params ride along into every page
        # the sentinel fetches afterwards.
        #
        # That is also why there is no submit button, no clear button and no form
        # around the band. The shape is taken from the inbox this was generalised
        # from, which filters the same way.
        class Component < ApplicationViewComponent
          BASE_CLASSES = "split-view-filter"
          COUNT_CLASSES = "split-view-filter-count"

          attr_reader :label, :href, :count

          # label  - the pill's text.
          # href   - where clicking it goes. For the ACTIVE pill this is normally
          #          the URL *without* its param, so clicking it again clears the
          #          filter — which is what replaces a Clear button.
          # active - whether this pill is the current filter. Drives `aria-current`
          #          and the styling; the caller decides, since only it knows what
          #          its params mean.
          # count  - optional number rendered after the label.
          def initialize(label:, href:, active: false, count: nil, **options)
            @label = label
            @href = href
            @active = active
            @count = count
            @options = options
          end

          def active? = !!@active

          private

          attr_reader :options

          def link_attributes
            options.except(:class, :aria).merge(
              class: class_names(BASE_CLASSES, options[:class]),
              # "true" and not "page": the pill is the current item of a set, and
              # the page is the listing, not the filter. Same call the ViewSwitch
              # makes for a selector that slices data rather than navigating to a
              # sibling view.
              aria: (options[:aria] || {}).merge(current: (active? ? "true" : nil))
            )
          end
        end
      end
    end
  end
end
