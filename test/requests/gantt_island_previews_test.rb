# frozen_string_literal: true

require "test_helper"

# The gantt island previews are markup plus the react_island_meta_tags helper
# — the same glue as the react-island demo. What can break server-side: the
# helper not reaching the preview template, the values not serializing, or
# the editable preview 500ing without/with a seeded project. Cypress covers
# the mount; this pins the 200 and the contract elements the loader needs.
class GanttIslandPreviewsTest < ActionDispatch::IntegrationTest
  def test_the_readonly_preview_renders_the_island_element_and_loader_metas
    get "/lookbook/preview/bali/gantt/island_readonly"

    assert_response :ok
    assert_select "[data-controller='gantt']", { minimum: 1 },
      "el preview renderizó sin el elemento de la isla"
    assert_select "meta[name='bali-gantt-js']", { minimum: 1 },
      "falta la meta del bundle que el loader necesita"
    assert_select "[data-gantt-data-value]", { minimum: 1 }
    assert_select "[data-gantt-i18n-value]", { minimum: 1 }
  end

  def test_the_editable_preview_wires_the_dummy_endpoints
    project = Project.create!(name: "Island Preview Project")
    project.tasks.create!(title: "Dated", status: :todo, phase: "Phase 1",
                          start_date: Date.current, due_date: Date.current + 5)

    get "/lookbook/preview/bali/gantt/island"

    assert_response :ok
    assert_select "[data-gantt-editable-value='true']"
    assert_select "[data-gantt-manageable-value='true']"
    assert_select "[data-gantt-patch-url-value='/admin/projects/#{project.id}/schedule']"
    assert_select "[data-gantt-dependencies-url-value='/admin/projects/#{project.id}/dependencies']"
    assert_select "[data-gantt-catalogs-value]"
  end

  def test_the_editable_preview_explains_itself_without_seed_data
    Project.destroy_all

    get "/lookbook/preview/bali/gantt/island"

    assert_response :ok
    assert_select "[data-controller='gantt']", count: 0
  end
end
