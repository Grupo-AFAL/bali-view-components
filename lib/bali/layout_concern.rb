# frozen_string_literal: true

# Complements the JavaScript ModalController in order to tell
# Rails that it shouldn't render a layout since the contents of the
# view will be rendered within a Modal.
#
module Bali
  module LayoutConcern
    extend ActiveSupport::Concern

    included do
      class_attribute :conditional_layout
      layout :conditionally_skip_layout
      helper_method :drawer_request?
    end

    def conditionally_skip_layout
      drawer_request? ? false : self.class.conditional_layout
    end

    # True when the Modal/Drawer controller fetched this page in order to drop it
    # into an overlay. It is the same `?layout=false` the layout switch above
    # reads, named once instead of spelled out at every call site.
    #
    # It is a helper because the page components autodetect their context through
    # it (see Bali::PageComponents::Shared#drawer?), which is what keeps `params`
    # out of the templates AND out of the components.
    def drawer_request?
      params[:layout] == "false"
    end
  end
end
