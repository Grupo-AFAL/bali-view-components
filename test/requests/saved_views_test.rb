# frozen_string_literal: true

require "test_helper"

# B2 — endpoints del storage default (Bali::SavedViewsController). El dueño lo resuelve
# `Bali.saved_views_owner` (default: current_user del host); aquí se inyecta por config,
# igual que hace el host con su sesión.
class BaliSavedViewsRequestTest < ActionDispatch::IntegrationTest
  STORAGE = "movies_index"

  def setup
    @owner = User.create!(name: "Ana")
    @orig_owner_resolver = Bali.saved_views_owner
    @orig_authorize = Bali.saved_views_authorize
    resolved = @owner
    Bali.saved_views_owner = ->(_controller) { resolved }
  end

  def teardown
    Bali.saved_views_owner = @orig_owner_resolver
    Bali.saved_views_authorize = @orig_authorize
  end

  def own_view!(owner: @owner, name: "Míos")
    Bali::SavedView.create!(owner: owner, storage_id: STORAGE, name: name,
                            payload: { "attributes" => {} })
  end

  def test_create_saves_a_view_for_the_resolved_owner_with_the_sliced_payload
    assert_difference "Bali::SavedView.count", 1 do
      post bali.saved_views_path(storage_id: STORAGE), params: {
        name: "Terminadas",
        payload: { "attributes" => { "status_eq" => "done" }, "hax" => "x" }.to_json
      }
    end
    assert_response :redirect

    view = Bali::SavedView.last
    assert_equal @owner, view.owner
    assert_equal STORAGE, view.storage_id
    assert_equal({ "attributes" => { "status_eq" => "done" } }, view.payload)
  end

  def test_create_with_the_same_name_upserts_instead_of_duplicating
    own_view!(name: "Terminadas")

    assert_no_difference "Bali::SavedView.count" do
      post bali.saved_views_path(storage_id: STORAGE), params: {
        name: "Terminadas", payload: { "attributes" => { "status_eq" => "done" } }.to_json
      }
    end
    assert_equal({ "attributes" => { "status_eq" => "done" } },
                 Bali::SavedView.find_by!(name: "Terminadas").payload)
  end

  def test_update_renames_an_own_view
    view = own_view!

    patch bali.saved_view_path(view), params: { name: "Míos 2026" }
    assert_response :redirect
    assert_equal "Míos 2026", view.reload.name
  end

  def test_destroy_deletes_an_own_view
    view = own_view!

    assert_difference "Bali::SavedView.count", -1 do
      delete bali.saved_view_path(view)
    end
    assert_response :redirect
  end

  def test_a_foreign_view_is_a_404_for_update_and_destroy
    foreign = own_view!(owner: User.create!(name: "Otra"), name: "Ajena")

    patch bali.saved_view_path(foreign), params: { name: "Robada" }
    assert_response :not_found
    assert_equal "Ajena", foreign.reload.name

    assert_no_difference "Bali::SavedView.count" do
      delete bali.saved_view_path(foreign)
    end
    assert_response :not_found
  end

  def test_without_a_resolved_owner_every_mutation_is_forbidden
    Bali.saved_views_owner = ->(_controller) { nil }

    assert_no_difference "Bali::SavedView.count" do
      post bali.saved_views_path(storage_id: STORAGE), params: { name: "X", payload: "{}" }
    end
    assert_response :forbidden
  end

  def test_the_authorize_hook_can_harden_access_beyond_owner_presence
    Bali.saved_views_authorize = ->(_controller, _owner) { false }

    assert_no_difference "Bali::SavedView.count" do
      post bali.saved_views_path(storage_id: STORAGE), params: { name: "X", payload: "{}" }
    end
    assert_response :forbidden
  end
end
