# frozen_string_literal: true

module Bali
  module DataTable
    module SavedViews
      # DataTable "Views" dropdown (B2): apply, save the current one, rename and delete named
      # filter combinations. The storage does NOT live here: the FilterForm brings a
      # `saved_views_store` (read only) and mutations are POSTed to the app's URL (`url:`) —
      # create at `url`, update/delete at `url/:id` (the app's RESTful routes).
      #
      # `default_views:` are STATIC shortcuts (not persisted) that the app defines — {name:,
      # url:} pairs ready to navigate to; they are painted in their own "Suggested" section.
      class Component < ApplicationViewComponent
        include Bali::DataTable::ListingIdentity

        DefaultView = Struct.new(:name, :url, keyword_init: true)

        # @param filter_form [Bali::FilterForm] with saved_views_store configured
        # @param url [String] the app's RESTful base for creating/renaming/deleting views
        # @param base_url [String] URL of the listing where they are applied (?saved_view=<id>)
        # @param listing_id [String] listing identity (to capture the selector's visible
        #   columns when saving; see Bali::DataTable::ListingIdentity)
        # @param default_views [Array<Hash>] static shortcuts {name:, url:}
        def initialize(filter_form:, url:, base_url:, listing_id: nil, default_views: nil)
          @filter_form = filter_form
          @url = url
          @base_url = base_url.to_s
          @listing_id = listing_id.to_s.delete_prefix("#")
          @default_views = Array(default_views).map { |view| DefaultView.new(**view.to_h.symbolize_keys) }
        end

        attr_reader :filter_form, :url, :listing_id, :default_views

        # With no URL no mutation is possible (happens when the slot did not receive `url:`
        # and the form has no storage_id to build the engine's default): painting nothing beats
        # painting broken forms.
        def render?
          filter_form&.saved_views_enabled? && url.present?
        end

        def views
          filter_form.saved_views
        end

        def current_view
          filter_form.current_saved_view
        end

        # The ACTIVE view marked in the dropdown, which also names the button. Priority: the
        # one applied by URL (?saved_view=), then the personal one whose payload matches the
        # form's current state (it survives persistence, which rewrites the URL clean), and
        # last the static shortcut whose query matches. Only one wins: no double marking.
        def active_view
          return @active_view if defined?(@active_view)

          @active_view = current_view ||
                         views.find { |view| filter_form.view_matches_current_state?(view) } ||
                         default_views.find { |view| default_view_active?(view) }
        end

        def button_label
          active_view ? active_view.name : t(".button_label")
        end

        def active_view?(view)
          view.equal?(active_view) ||
            (!view.is_a?(DefaultView) && !active_view.is_a?(DefaultView) &&
             active_view&.id == view.id)
        end

        # Marker for the active item. NOT `menu-active`: in daisyUI 5 that class paints the
        # item with `neutral`, i.e. a solid black block that eats the rest of the menu. This
        # repo's standard for "this is the selected one" inside a list is primary text with no
        # background — same as SlimSelect (`.ss-selected`, slim_select.css:607) and as the
        # sibling "Group by" dropdown (GroupByControl#item_class).
        def active_item_class(view)
          "text-primary font-medium" if active_view?(view)
        end

        # The view being worked on, even once its filters have been changed (it survives the
        # submit via `view_origin`). It is the one offered for UPDATE.
        def origin_view = filter_form.saved_view_origin

        # Updating is only offered when there is something to come from AND the state changed:
        # with the state intact the button would promise to save something already saved.
        def updatable? = filter_form.saved_view_dirty?

        def update_label = t(".update_current", name: origin_view.name)

        def update_confirm = t(".update_confirm", name: origin_view.name)

        # With a modified view, saving again means "save as NEW": the text says so, so it is
        # not confused with updating the one that already exists.
        def save_label = updatable? ? t(".save_as_new") : t(".save_current")

        def apply_url(view)
          "#{@base_url}#{@base_url.include?('?') ? '&' : '?'}saved_view=#{view.id}"
        end

        # The id is inserted into the PATH (not at the end of the raw URL): a `url` with a
        # query string (e.g. ?storage_id=...) must keep it after the id.
        def view_url(view)
          path, query = url.split("?", 2)
          "#{path.chomp('/')}/#{view.id}#{"?#{query}" if query}"
        end

        # Payload of the current state, serialized for the save form's hidden field. The
        # visible columns are added by the Stimulus controller on submit (they live in the
        # selector's DOM).
        def payload_json
          filter_form.current_view_payload.to_json
        end

        # Columns the applied view IMPOSED. The selector is only painted in table mode, and
        # without it the JS fell back to localStorage — which is the device memory from BEFORE
        # the view: saving a new view from cards persisted it with columns the user was not
        # looking at.
        def server_columns_json
          Array(filter_form.try(:saved_view_columns)).map(&:to_i).to_json
        end

        private

        # A static shortcut is active when its URL's query describes the SAME state the form
        # has applied. Its query is translated into the payload's shape: q[g]→groupings,
        # q[m]→combinator, the search predicate→search_value (the form carries it there, not in
        # attributes), `group_by` (a top-level param, outside q) and the rest of q→attributes.
        # Translating less gave both false positives (a shortcut that only groups normalized to
        # empty) and false negatives (a shortcut with a search never matched).
        def default_view_active?(view)
          uri = URI.parse(view.url.to_s)
          params = uri.query.present? ? Rack::Utils.parse_nested_query(uri.query) : {}
          q = params.fetch("q", {})
          q = {} unless q.is_a?(Hash)
          filter_form.state_matches_current_state?(
            "attributes" => q.except("g", "m", *search_predicate),
            "groupings" => q["g"],
            "combinator" => q["m"],
            "search_value" => search_predicate && q[search_predicate],
            "group_by" => params["group_by"]
          )
        rescue URI::InvalidURIError
          false
        end

        # Combined predicate emitted by the quick search (e.g. "name_or_code_cont"), or nil if
        # this listing has no search.
        def search_predicate
          return @search_predicate if defined?(@search_predicate)

          fields = filter_form.try(:search_config)&.dig(:fields)
          @search_predicate = Bali::RansackParamName.predicate(fields)
        end
      end
    end
  end
end
