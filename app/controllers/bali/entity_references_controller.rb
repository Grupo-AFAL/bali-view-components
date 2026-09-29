# frozen_string_literal: true

module Bali
  # #708 — the two endpoints the BlockEditor's `#` needs, for ALL the types the host has
  # declared in `Bali.entity_reference_types` (one per type was the design this replaces).
  #
  #   GET  bali/entity_references?q=text    → autocomplete
  #   GET  bali/entity_references?refs[][entityType]=...&refs[][entityId]=...
  #   POST bali/entity_references/resolve   → {refs: [...]} (the one the JS uses on load)
  #
  # Authorization: this controller does NOT inherit the host ApplicationController's hooks,
  # so the gate lives inside and `Bali.entity_references_authorize` DENIES by default —
  # without it, mounting the engine would publish a search over the app's records. The
  # fine-grained per-type filter is `permission_scope:` on each registry entry.
  class EntityReferencesController < ApplicationController
    # Cap on refs per request. The JS sends those of the open document, already
    # deduplicated, so a real document never comes close to it; it exists because the POST
    # body is written by the client and without a cap a single request would ask for an IN
    # of arbitrary size.
    MAX_REFS = 500

    before_action :authorize_entity_references!

    def index
      return render json: resolver.resolve(permitted_refs) if params[:refs].present?
      return render json: resolver.search(params[:q]) if params[:q].present?

      render json: []
    end

    def resolve
      render json: resolver.resolve(permitted_refs)
    end

    private

    def authorize_entity_references!
      head :forbidden unless Bali.entity_references_authorize.call(self)
    end

    def resolver = EntityReference::Resolver.new(controller: self)

    # Only the contract's two keys survive: the rest of the body does not reach the
    # resolver, which uses them to group and to query by id.
    def permitted_refs
      Array(params[:refs]).first(MAX_REFS).filter_map { |ref| permit_ref(ref) }
    end

    def permit_ref(ref)
      return ref.permit(:entityType, :entityId).to_h if ref.respond_to?(:permit)
      return ref.stringify_keys.slice("entityType", "entityId") if ref.is_a?(Hash)

      nil
    end
  end
end
