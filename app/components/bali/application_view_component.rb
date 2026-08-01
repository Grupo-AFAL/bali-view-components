# frozen_string_literal: true

module Bali
  class ApplicationViewComponent < ViewComponentContrib::Base
    include HtmlElementHelper
    include PathHelper

    # One i18n root for the whole gem, matching the rest of the bali-* family
    # (bali-auth, bali-inbox each get their own). This is what `t('.key')`
    # inside a component resolves against: view_component-contrib builds the
    # scope as "#{i18n_namespace}.#{contrib_i18n_scope}", so the namespace alone
    # moves every relative key off `view_components.*`, which is a namespace the
    # gem was squatting in the host's locale tree.
    self.i18n_namespace = "bali_view"

    # …and the class-name-derived half drops its leading "bali", which the
    # namespace now carries: `Bali::Rate::Component` scopes to `bali_view.rate`,
    # not `bali_view.bali.rate`.
    def self.contrib_i18n_scope
      @contrib_i18n_scope ||= name.to_s.sub("::Component", "").underscore.split("/").drop(1)
    end

    private

    def identifier
      @identifier ||= self.class.name.sub("::Component", "").underscore.split("/").join("--")
    end
  end
end
