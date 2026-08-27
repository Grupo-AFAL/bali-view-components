# frozen_string_literal: true

module Bali
  # The controller-side seam for FilterForm persistence (#999).
  #
  # Persistence needs three things only the request can answer — the listing's
  # identity, whose filters these are, and whether this browser opted in — and
  # each one was an internal contract of the engine leaking into every host
  # controller: the `bali_persist_*` cookie format, the "context or the cache
  # is process-global" trap, and a storage id that is always a derivation of
  # the controller. Forgetting any of the three renders perfectly fine and
  # never restores: the failure mode is 100% silent (it happened to two apps
  # before this concern existed).
  #
  #   class ApplicationController < ActionController::Base
  #     include Bali::Filterable
  #   end
  #
  #   # In the action — the three kwargs are gone:
  #   @filter_form = filter_form(AccountsFilterForm, policy_scope(Account))
  #
  # Every explicit kwarg still passes straight through, so this is additive:
  # `filter_form(Klass, scope, storage_id: "bulk_provision_#{@app.id}",
  # view_param: :mode)` works, and `context:`/`persist_enabled:` win over the
  # derived values when given.
  module Filterable
    extend ActiveSupport::Concern

    # Builds a FilterForm with the persistence circuit closed.
    #
    # storage_id      - defaults to `controller_path` with slashes dashed
    #   (`admin/accounts` → `"admin-accounts"`). Derived from the controller and
    #   NOT from the form class: one form class can serve several listings
    #   (an AccountsFilterForm on the accounts index AND on a bulk-provision
    #   page), and the class name would collide them. Pass it explicitly for
    #   per-record identities (`storage_id: "bulk_provision_#{@app.id}"`).
    # context         - defaults to `Bali.filter_context.call(self)`. Pass
    #   `context: nil` explicitly to opt out of scoping on purpose.
    # persist_enabled - defaults to reading the `bali_persist_<storage_id>`
    #   cookie the PersistenceToggle writes, returning that format to being an
    #   internal detail between the JS and the engine.
    def filter_form(klass, scope, storage_id: nil, context: :__bali_derive__,
                    persist_enabled: nil, **options)
      storage_id ||= bali_derived_storage_id
      context = Bali.filter_context&.call(self) if context == :__bali_derive__
      persist_enabled = filter_persistence_enabled?(storage_id) if persist_enabled.nil?

      klass.new(scope, params, storage_id: storage_id, context: context,
                persist_enabled: persist_enabled, **options)
    end

    # Whether this browser opted into filter persistence for a listing — the
    # `bali_persist_<storage_id>` cookie the PersistenceToggle writes.
    #
    # Public because a host that decides anything at all from that signal — a redirect
    # to a default filter, a banner, a different empty state — would otherwise spell the
    # cookie name itself, and the whole point of this concern is that the name lives on
    # one side of the wall (#1096). `storage_id` defaults to the same derivation
    # {#filter_form} uses, so the no-argument call answers for THIS listing.
    def filter_persistence_enabled?(storage_id = nil)
      cookies["bali_persist_#{storage_id || bali_derived_storage_id}"] == "1"
    end

    # Sends a bare listing URL to the same URL carrying the form's `default:` filters, so
    # a listing that opens on a question says so in the URL (#1096).
    #
    #   def index
    #     return if redirect_to_default_filters(PeopleFilterForm)
    #
    #     @filter_form = filter_form(PeopleFilterForm, policy_scope(Person))
    #   end
    #
    # The URL is the only place the default can live — see {Bali::FilterForm::DefaultFilters}
    # for why the scope and the widget both fail — and putting it there is also what makes
    # it behave like a filter: visible as a condition, removable, shareable in a link, and
    # still applied after sorting and paging.
    #
    # Four things turn it off, and each one is the user having already answered:
    #
    # - `q` in the URL — they filtered, sorted, or emptied the panel;
    # - `clear_filters` — they cleared on purpose, and the redirect would undo the click;
    # - `saved_view` — a view is a complete state, not something to merge a default into;
    # - filter persistence on for this listing — that toggle promises "remember what I
    #   chose", and a default written into the URL on every bare entry is filter params
    #   as far as the form can tell, so it would store the default and never restore
    #   anything else. Persistence would be off for that listing and nothing would say so.
    #
    # @param form [Class, Hash] the FilterForm subclass whose `default:` declarations
    #   apply — or the `q` hash itself, for a listing built with instance-level
    #   `simple_filters:` (whose defaults no class can be asked for) or one whose default
    #   depends on the request
    # @param storage_id [String] the listing's persistence identity, when it is not the
    #   one {#filter_form} derives
    # @return [Boolean] true when it redirected, so the action can return
    def redirect_to_default_filters(form, storage_id: nil)
      return false unless request.get?
      return false if params[:q].present? || params[:clear_filters].present? ||
                      params[:saved_view].present?
      return false if filter_persistence_enabled?(storage_id)

      defaults = form.respond_to?(:default_filter_params) ? form.default_filter_params : form
      return false if defaults.blank?

      redirect_to "#{request.path}?#{request.query_parameters.merge('q' => defaults).to_query}"
      true
    end

    private

    def bali_derived_storage_id
      controller_path.tr("/", "-")
    end

    # @deprecated Removed in Bali 4.0. Use the public {#filter_persistence_enabled?}.
    #
    # Private, but reachable: a concern's private methods are the host controller's
    # private methods, and an app that needed the signal before it was public called
    # this one (Grupo-AFAL/gobierno-corporativo#877). Renaming it out from under them
    # would fail the exact way #1096 is about — silently, with the redirect it guards
    # simply no longer guarded.
    def bali_filter_persistence_cookie?(storage_id)
      Bali.deprecator.warn(
        "Bali::Filterable#bali_filter_persistence_cookie? is private and deprecated. " \
        "Call `filter_persistence_enabled?(storage_id)`, which is public API."
      )
      filter_persistence_enabled?(storage_id)
    end
  end
end
