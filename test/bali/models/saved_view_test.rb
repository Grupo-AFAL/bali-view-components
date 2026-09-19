# frozen_string_literal: true

require "test_helper"

class BaliSavedViewTest < ActiveSupport::TestCase
  def owner
    @owner ||= User.create!(name: "Ana")
  end

  def build_view(**attrs)
    Bali::SavedView.new(owner: owner, storage_id: "movies_index", name: "Míos", **attrs)
  end

  def test_valid_with_owner_storage_id_and_name
    assert_predicate build_view, :valid?
  end

  def test_name_is_unique_per_owner_and_storage_but_repeatable_across_them
    build_view.save!

    assert_not build_view.valid?, "mismo owner+storage+name debe rechazarse"
    assert_predicate build_view(storage_id: "otro_listado"), :valid?
    assert_predicate build_view(owner: User.create!(name: "Otra")), :valid?
    # The uniqueness scope includes owner_type: another KIND of owner (phase 2: teams/roles) may
    # repeat a name even when it shares a numeric id with a user.
    assert_predicate build_view(owner: Tenant.create!(name: "Equipo")), :valid?
  end

  def test_payload_accepts_the_filter_form_contract_as_json_string_and_slices_the_rest
    view = build_view(payload: { "attributes" => { "name_i_cont" => "a" },
                                 "columns" => [ 0, 2 ], "malicioso" => "x" }.to_json)

    assert_equal({ "attributes" => { "name_i_cont" => "a" }, "columns" => [ 0, 2 ] }, view.payload)
  end

  def test_payload_swallows_invalid_json_and_non_hashes_into_an_empty_hash
    assert_equal({}, build_view(payload: "no-json{").payload)
    assert_equal({}, build_view(payload: [ 1, 2 ]).payload)
  end

  # --- Store: the default implementation of the saved_views_store contract ---

  def test_store_lists_only_the_owner_and_storage_scope_ordered_by_name_and_upserts_by_name
    store = Bali::SavedView.store_for(owner, "movies_index")
    store.save(name: "Zeta", payload: { "attributes" => {} })
    store.save(name: "Alfa", payload: { "attributes" => {} })
    # Noise outside the scope: another storage, another owner and another KIND of owner.
    build_view(storage_id: "otro_listado", name: "Ajena storage").save!
    build_view(owner: User.create!(name: "Otra"), name: "Ajena usuario").save!
    build_view(owner: Tenant.create!(name: "Equipo"), name: "Ajena tipo").save!

    assert_equal %w[Alfa Zeta], store.list.map(&:name)

    # Upsert by name: it does not duplicate, it updates the payload.
    updated = store.save(name: "Alfa", payload: { "attributes" => { "status_eq" => "done" } })
    assert_equal 2, store.list.size
    assert_equal({ "attributes" => { "status_eq" => "done" } }, updated.payload)

    # find/delete stay inside the scope: somebody else's view is neither found nor deleted.
    foreign = Bali::SavedView.find_by!(name: "Ajena usuario")
    assert_nil store.find(foreign.id)
    store.delete(foreign.id)
    assert Bali::SavedView.exists?(foreign.id), "delete fuera del scope es un no-op"
  end
end
