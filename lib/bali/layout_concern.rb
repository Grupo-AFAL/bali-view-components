# frozen_string_literal: true

# Complements the JavaScript ModalController in order to tell
# Rails that it shouldn't render a layout since the contents of the
# view will be rendered within a Modal.
#
module Bali
  module LayoutConcern
    extend ActiveSupport::Concern

    # The layout turbo-rails renders a frame response in. Named here rather than reached
    # by falling through to it, because there is no falling through (#1097).
    #
    # `layout :a_symbol` compiles to "call the method; if it returns nil, look up
    # `layouts/<implied name>` and only if THAT misses, call super"
    # (ActionView::Layouts#_write_layout_method). The concern is included in
    # `ApplicationController`, so the implied name is `application` — a template every real
    # app has. The lookup therefore always hits and `super` never runs, which makes the
    # `layout -> { "turbo_rails/frame" if turbo_frame_request? }` that turbo-rails declares
    # on `ActionController::Base` unreachable for as long as this concern is included: every
    # frame request gets the full application shell, silently. Answering the frame here is
    # the only place the answer fits.
    #
    # An app that supplies its own `app/views/layouts/turbo_rails/frame.html.erb` still
    # wins — that is turbo-rails' own documented override point, and this names the same
    # path it does.
    TURBO_FRAME_LAYOUT = "turbo_rails/frame"

    included do
      class_attribute :conditional_layout
      layout :conditionally_skip_layout
      helper_method :drawer_request?
    end

    # The drawer beats the frame on purpose: `false` (no layout at all) is smaller than the
    # frame layout, and a response headed for a `#main-drawer` does not want even that
    # `<html>`. A frame beats `conditional_layout` for the mirror reason — an admin shell
    # inside a frame is the duplicated chrome the frame exists to avoid.
    def conditionally_skip_layout
      return false if drawer_request?
      return TURBO_FRAME_LAYOUT if turbo_frame_layout_request?

      self.class.conditional_layout
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

    private

    # `include_all: true` is load-bearing: turbo-rails declares `turbo_frame_request?`
    # under its own `private`, so a plain `respond_to?` answers false in every app that
    # has the gem and the frame case stays broken.
    #
    # The `respond_to?` at all is because turbo-rails is not a dependency of this gem — a
    # host that renders no frames must not be asked for a predicate nothing defined.
    def turbo_frame_layout_request?
      respond_to?(:turbo_frame_request?, true) && turbo_frame_request?
    end
  end
end
