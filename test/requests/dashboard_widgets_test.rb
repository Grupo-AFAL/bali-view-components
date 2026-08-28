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
    Bali::DashboardWidget::Store.new(owner: User.demo, dashboard_key: "demo",
                                     offering: DemoWidgets.authorized_for(User.demo))
  end

  # THE INDEX ACTION, which nothing else covers. The component tests all drive
  # synthetic widgets against `Bali::Widget::Component` directly, so a break in
  # the page around them — a bad `regions` override, a typo in the grid's ERB,
  # a demo widget whose declaration stopped resolving — would not fail anything.
  # This renders the real ten against the real database.
  def test_the_dashboard_renders_every_offered_widget
    get dashboard_widgets_path

    assert_response :success
    DemoWidgets.authorized_for(User.demo).each do |widget|
      assert_select %(section[data-widget-key="#{widget.key}"]), 1,
                    "#{widget.key} did not render"
    end
  end

  # A widget that raises must degrade its own tile, never the page. The demo
  # offering ships one that reports failure, so the index is the place this is
  # visible end to end rather than in a component test's synthetic widget.
  def test_a_failed_widget_does_not_take_the_page_down
    get dashboard_widgets_path

    assert_response :success
    assert_select %(section[data-widget-key="unavailable_feed"]) do
      assert_select ".text-warning"
    end
  end

  def test_update_persists_an_authorized_widget
    patch dashboard_widgets_path, params: {
      widgets: [ { key: "recent_movies", size: "large" } ]
    }
    assert_response :no_content

    assert_equal %w[recent_movies], store.stored_keys
    assert_equal :large, store.widgets.first.size
  end

  # `OverdueTasks` is a `ValueBase`, which supports `:small` alone — a bare figure
  # has nothing to fill a bigger canvas. A stored size it does not offer falls
  # back to its default rather than refusing to render.
  def test_a_size_a_widget_does_not_offer_falls_back_to_its_default
    patch dashboard_widgets_path, params: {
      widgets: [ { key: "overdue_tasks", size: "large" } ]
    }

    assert_equal :small, store.widgets.first.size
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
