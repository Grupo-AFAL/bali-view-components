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
      storage_id ||= controller_path.tr("/", "-")
      context = Bali.filter_context&.call(self) if context == :__bali_derive__
      persist_enabled = bali_filter_persistence_cookie?(storage_id) if persist_enabled.nil?

      klass.new(scope, params, storage_id: storage_id, context: context,
                persist_enabled: persist_enabled, **options)
    end

    private

    # The cookie filter-persistence-controller.js writes on toggle:
    # `bali_persist_<storage_id>=1`.
    def bali_filter_persistence_cookie?(storage_id)
      cookies["bali_persist_#{storage_id}"] == "1"
    end
  end
end
