# frozen_string_literal: true

module Bali
  class ApplicationViewComponentPreview < ViewComponentContrib::Preview::Base
    self.abstract_class = true

    include Pagy::Method

    def form_record
      @form_record ||= FormRecord.new
    end

    private

    # Pagy::Method requires a request object. Pagy::Request accepts a plain Hash
    # for non-Rack contexts like Lookbook previews.
    #
    # `path: nil` and not the preview's own URL, because a preview has no single URL: the
    # same render is served at `/lookbook/preview/<path>/<scenario>` and inside the
    # inspector's iframe, and the preview instance — built by `ViewComponent::Preview.new`
    # — never sees the request either way. Pagy composes `path || @request.path`, so a nil
    # path yields a bare `?page=2` that the browser resolves against whichever of those two
    # the reader is actually on. This used to be the literal string "/lookbook", which is
    # neither of them: every page link in every paginating preview pointed at Lookbook's
    # home page, so clicking page 2 threw the reader out of the component they were reading
    # (#756).
    #
    # `params` stays empty, so a preview's own params (`?view=grid`) do not survive a page
    # click. Only the preview method knows them, so a preview that needs them has to pass
    # its own `request:` to `pagy()`.
    def request
      { base_url: "", path: nil, params: {}, cookie: nil }
    end
  end
end
