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

    # A keyword that names one of the component's own slots is a mistake, and the silent
    # kind (#1081). `Bali::Card::Component.new(title: "Data")` does not fail: `title:` is
    # not a parameter, so it falls into the component's `**options`, and the options are
    # dumped on the root element — the card comes out with an HTML `title` attribute (a
    # tooltip) and no heading. Valid HTML, no exception, no warning, and the text is even
    # in the body, so `assert_match` in a test passes too. Ten cards in one host app went
    # months without their heading this way.
    #
    # It reads as correct because sibling components (StatCard, Tabs#with_tab, Message)
    # DO take `title:` as a parameter. The rule this enforces is the one that tells them
    # apart: if the class declares a slot by that name, the keyword belongs to the slot.
    #
    # Only components whose `initialize` has a `**rest` need this — without one, Ruby's
    # own "unknown keyword" ArgumentError already says it, and says it better.
    def self.new(*args, **kwargs, &block)
      reject_slot_keywords!(kwargs) if Bali.raise_on_slot_keyword_conflict
      super
    end

    # Cached per class: `registered_slots` and the initializer's signature are both fixed
    # at class-definition time, and a code reload replaces the class object itself.
    def self.slot_keywords
      @slot_keywords ||= begin
        parameters = instance_method(:initialize).parameters

        if parameters.any? { |type, _| type == :keyrest }
          declared = parameters.filter_map { |type, name| name if %i[key keyreq].include?(type) }
          registered_slots.keys.map(&:to_sym) - declared
        else
          []
        end
      end
    end

    def self.reject_slot_keywords!(kwargs)
      return if kwargs.empty?

      conflicts = slot_keywords & kwargs.keys
      return if conflicts.empty?

      raise ArgumentError, slot_keyword_message(conflicts)
    end

    def self.slot_keyword_message(conflicts)
      keywords = conflicts.map { |slot| "`#{slot}:`" }.to_sentence
      setters = conflicts.map { |slot| "`with_#{slot}`" }.to_sentence

      "#{keywords} #{conflicts.one? ? "names a slot" : "name slots"} of #{name}, not " \
        "#{conflicts.one? ? "an option" : "options"} of it: the keyword lands in the " \
        "component's HTML attributes, so the content silently never renders. Use " \
        "#{setters}. To set the HTML attribute on purpose, write the key as a string " \
        "(`\"#{conflicts.first}\" => ...`)."
    end

    private

    def identifier
      @identifier ||= self.class.name.sub("::Component", "").underscore.split("/").join("--")
    end
  end
end
