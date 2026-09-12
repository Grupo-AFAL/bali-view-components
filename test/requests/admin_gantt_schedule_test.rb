# frozen_string_literal: true

require "test_helper"

# The dummy's schedule endpoints are the EXECUTABLE reference of the
# Bali::Gantt mutation contract (#705, D15/D17): every mutation answers with
# the COMPLETE document; 422 { errors } tells the island to roll back; 404
# tells it to re-GET. The island's scheduleClient.js and phase 3's
# docs/api/gantt.md both lean on exactly these behaviors.
class AdminGanttScheduleTest < ActionDispatch::IntegrationTest
  def setup
    @project = Project.create!(name: "Contract Project")
    @a = @project.tasks.create!(title: "A", status: :in_progress, phase: "Build",
                                start_date: Date.new(2026, 8, 3), due_date: Date.new(2026, 8, 7),
                                percent_complete: 40)
    @b = @project.tasks.create!(title: "B", status: :todo, phase: "Build",
                                start_date: Date.new(2026, 8, 10), due_date: Date.new(2026, 8, 14))
    @c = @project.tasks.create!(title: "C (undated)", status: :backlog)
    @dep = TaskDependency.create!(predecessor: @a, successor: @b)
  end

  def test_get_returns_the_complete_document
    get "/admin/projects/#{@project.id}/schedule"

    assert_response :ok
    doc = response.parsed_body.deep_symbolize_keys
    assert_equal %i[groups items dependencies critical_ids].sort, doc.keys.sort
    assert_equal [ @a.id, @b.id, @c.id ].sort, doc[:items].map { |i| i[:id] }.sort
    assert_equal "build", doc[:items].find { |i| i[:id] == @a.id }[:group_id]
    assert_equal [ { id: @dep.id, predecessor_id: @a.id, successor_id: @b.id,
                    dependency_type: "finish_to_start", lag_days: 0 } ],
                 doc[:dependencies]
    # Fake CPM: the only chain (A → B) is the critical path.
    assert_equal [ @a.id, @b.id ], doc[:critical_ids]
  end

  def test_patch_moves_an_item_and_returns_the_recalculated_document
    patch "/admin/projects/#{@project.id}/schedule",
          params: { item: { id: @a.id, starts_on: "2026-08-05", duration_days: 3 } },
          as: :json

    assert_response :ok
    assert_equal Date.new(2026, 8, 5), @a.reload.start_date
    assert_equal Date.new(2026, 8, 7), @a.due_date # inclusive: 3 days

    item = response.parsed_body["items"].find { |i| i["id"] == @a.id }
    assert_equal "2026-08-05", item["starts_on"]
    assert_equal "2026-08-07", item["ends_on"]
  end

  def test_patch_unknown_item_is_404_so_the_client_re_syncs
    patch "/admin/projects/#{@project.id}/schedule",
          params: { item: { id: 999_999, starts_on: "2026-08-05", duration_days: 1 } },
          as: :json

    assert_response :not_found
  end

  def test_patch_invalid_payload_is_422_with_errors
    patch "/admin/projects/#{@project.id}/schedule",
          params: { item: { id: @a.id, starts_on: "not-a-date", duration_days: 2 } },
          as: :json

    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].any?

    patch "/admin/projects/#{@project.id}/schedule",
          params: { item: { id: @a.id, starts_on: "2026-08-05", duration_days: 0 } },
          as: :json

    assert_response :unprocessable_entity
    assert_equal Date.new(2026, 8, 3), @a.reload.start_date, "un 422 no debe mutar nada"
  end

  def test_post_dependency_returns_the_document_and_recomputes_criticals
    @c.update!(start_date: Date.new(2026, 8, 17), due_date: Date.new(2026, 8, 20))

    post "/admin/projects/#{@project.id}/dependencies",
         params: { dependency: { predecessor_id: @b.id, successor_id: @c.id } },
         as: :json

    assert_response :ok
    doc = response.parsed_body
    assert_equal 2, doc["dependencies"].size
    assert_equal [ @a.id, @b.id, @c.id ], doc["critical_ids"]
  end

  def test_post_cycle_or_self_link_is_422_so_the_island_rolls_back
    post "/admin/projects/#{@project.id}/dependencies",
         params: { dependency: { predecessor_id: @b.id, successor_id: @a.id } },
         as: :json

    assert_response :unprocessable_entity
    assert_match(/cycle/, response.parsed_body["errors"].join)

    post "/admin/projects/#{@project.id}/dependencies",
         params: { dependency: { predecessor_id: @a.id, successor_id: @a.id } },
         as: :json

    assert_response :unprocessable_entity
  end

  def test_delete_dependency_returns_the_document_without_it
    delete "/admin/projects/#{@project.id}/dependencies/#{@dep.id}"

    assert_response :ok
    doc = response.parsed_body
    assert_empty doc["dependencies"]
    assert_empty doc["critical_ids"], "sin dependencias no hay ruta crítica"
  end

  def test_delete_unknown_dependency_is_404
    delete "/admin/projects/#{@project.id}/dependencies/999999"

    assert_response :not_found
  end

  # The timeline view is the only place in the dummy that publishes an island's
  # assets the way a host does — `content_for :head` in the view, `yield(:head)`
  # in the layout (step 4 of docs/api/gantt.md). The Lookbook previews emit the
  # metas inline, so nothing else exercises that circuit, and it fails SILENTLY:
  # drop either half and the loader has nothing to inject, the island never
  # mounts, and the visitor is left with a skeleton announcing `aria-busy`
  # forever. The page answers 200 either way, so only these assertions catch it.
  def test_the_timeline_view_publishes_the_island_assets_through_the_layout
    get "/admin/projects/#{@project.id}?view=timeline"

    assert_response :ok
    assert_select "head meta[name=?]", "bali-gantt-js", { count: 1 },
      "content_for :head → yield(:head) roto: el loader no sabría qué inyectar"
    assert_select "head meta[name=?]", "bali-gantt-css", { count: 1 }
    assert_select "[data-controller='gantt'][data-gantt-patch-url-value=?]",
      "/admin/projects/#{@project.id}/schedule"
  end
end
