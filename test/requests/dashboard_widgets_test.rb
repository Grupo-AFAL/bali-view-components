# frozen_string_literal: true

require "test_helper"

# `DashboardWidgetsController` — `docs/guides/engine-models.md` ("Dashboard
# widgets") holds this up as the reference host controller to copy, so this
# is the boundary that actually matters: a submitted widget key becomes a
# widget only by lookup in the already-authorized offering, and an
# unauthorized or made-up key is silently dropped rather than persisted or
# rejected. `Bali::DashboardWidget::Store`'s own unit tests
# (test/bali/models/dashboard_widget/store_test.rb) prove the Store enforces
# this given a Ruby array of widget objects; this proves the controller
# actually turns raw request params into that array correctly.
class DashboardWidgetsRequestTest < ActionDispatch::IntegrationTest
  def store
    Bali::DashboardWidget.store_for(User.demo, dashboard_key: "demo",
                                               offering: DemoWidgets.authorized_for(User.demo))
  end

  def test_update_persists_an_authorized_widget
    patch dashboard_widgets_path, params: {
      widgets: [ { key: "overdue_tasks", size: "large" } ]
    }
    assert_response :no_content

    assert_equal %w[overdue_tasks], store.stored_keys
    assert_equal :large, store.widgets.first.size
  end

  def test_update_silently_drops_a_key_outside_the_offering
    patch dashboard_widgets_path, params: {
      widgets: [
        { key: "overdue_tasks", size: "" },
        { key: "totally_made_up_widget", size: "" }
      ]
    }
    assert_response :no_content

    # The unauthorized key never reaches the table — not stored as a row,
    # not surfaced as an error.
    assert_equal %w[overdue_tasks], store.stored_keys
  end

  def test_update_with_an_empty_widgets_submission_resets
    patch dashboard_widgets_path, params: { widgets: [ { key: "overdue_tasks", size: "" } ] }
    assert_equal %w[overdue_tasks], store.stored_keys

    # An emptied grid submits NO `widgets` params at all — not `widgets: []`,
    # which HTML form encoding cannot even express as distinct from a single
    # blank entry (`widgets[]=` parses back as `[""]`, not `[]`). This is the
    # shape `permitted_layout`'s blank check is actually guarding against.
    patch dashboard_widgets_path, params: {}
    assert_response :no_content

    assert_empty store.stored_keys
  end

  def test_update_picker_chooses_membership_and_drops_unauthorized_keys
    patch dashboard_widgets_picker_path, params: {
      widget_keys: [ "overdue_tasks", "recent_movies", "totally_made_up_widget" ]
    }
    assert_response :redirect

    assert_equal %w[overdue_tasks recent_movies], store.stored_keys
  end

  def test_reset_drops_every_row
    patch dashboard_widgets_path, params: { widgets: [ { key: "overdue_tasks", size: "" } ] }
    assert_equal %w[overdue_tasks], store.stored_keys

    delete reset_dashboard_widgets_path
    assert_response :redirect

    assert_empty store.stored_keys
  end
end
