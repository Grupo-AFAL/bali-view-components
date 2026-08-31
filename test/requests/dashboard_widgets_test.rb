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
  # What the concern builds for itself, rebuilt here so a test can look at the
  # rows behind a request.
  def offering
    Bali::Widget.authorized_for(
      DashboardWidgetsController.widget_catalog.map { |klass| klass.new(User.demo) }
    )
  end

  def store
    Bali::DashboardWidget::Store.new(owner: User.demo, dashboard_key: "demo", offering: offering)
  end

  # THE INDEX ACTION, which nothing else covers. The component tests all drive
  # synthetic widgets against `Bali::Widget::Component` directly, so a break in
  # the page around them — a bad `regions` override, a typo in the grid's ERB,
  # a demo widget whose declaration stopped resolving — would not fail anything.
  # This renders the real ten against the real database.
  def test_the_dashboard_renders_every_offered_widget
    get dashboard_widgets_path

    assert_response :success
    offering.each do |widget|
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
    patch arrange_dashboard_widgets_path, params: {
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
    patch arrange_dashboard_widgets_path, params: {
      widgets: [ { key: "overdue_tasks", size: "large" } ]
    }

    assert_equal :small, store.widgets.first.size
  end

  def test_update_silently_drops_a_key_outside_the_offering
    patch arrange_dashboard_widgets_path, params: {
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
    patch arrange_dashboard_widgets_path, params: { widgets: [ { key: "overdue_tasks", size: "" } ] }
    assert_equal %w[overdue_tasks], store.stored_keys

    # An emptied grid submits NO `widgets` params at all — not `widgets: []`,
    # which HTML form encoding cannot even express as distinct from a single
    # blank entry (`widgets[]=` parses back as `[""]`, not `[]`). This is the
    # shape `submitted_layout`'s blank check is actually guarding against.
    patch arrange_dashboard_widgets_path, params: {}
    assert_response :no_content

    assert_empty store.stored_keys
  end

  # `?widgets=lol` is a String, and `\"lol\"[:key]` raises `TypeError` — a 500 for
  # a malformed request that deserves a 400. This is what `params.expect` is in
  # `submitted_layout` for; the `blank?` guard above does not cover it, because
  # a scalar is not blank.
  def test_update_with_a_malformed_widgets_param_is_a_bad_request
    patch arrange_dashboard_widgets_path, params: { widgets: [ { key: "overdue_tasks", size: "" } ] }
    assert_equal %w[overdue_tasks], store.stored_keys

    patch arrange_dashboard_widgets_path, params: { widgets: "lol" }
    assert_response :bad_request

    # And nothing was written on the way to failing.
    assert_equal %w[overdue_tasks], store.stored_keys
  end

  # ONE URL FOR EVERY WIDGET: the card sends its own key and gets itself back as
  # a stream. `ProjectProgress` is the demo widget that declares `refresh_every`.
  def test_refresh_streams_back_the_named_card
    get refresh_dashboard_widgets_path(keys: [ "project_progress" ]),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal 1, response.body.scan("<turbo-stream").size
    assert_includes response.body, %(target="#{Bali::Widget::Component.dom_id('project_progress')}")
  end

  # Several keys in one request, so batching tiles into one tick stays a change
  # in the JavaScript alone.
  def test_refresh_takes_several_keys_at_once
    get refresh_dashboard_widgets_path(keys: %w[project_progress recent_movies]),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_equal 2, response.body.scan("<turbo-stream").size
  end

  # THE SIZE THE OWNER STORED, not the widget's default. Rendering the bare
  # widget would fall back to `default_size` and silently un-resize every card a
  # refresh touched.
  def test_refresh_renders_the_card_at_its_stored_size
    patch arrange_dashboard_widgets_path, params: { widgets: [ { key: "recent_movies", size: "small" } ] }

    get refresh_dashboard_widgets_path(keys: [ "recent_movies" ]),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_match(/data-size="small"/, response.body)
  end

  # The same silent drop as every other boundary — an unauthorized, retired or
  # invented key is simply absent from the response.
  def test_refresh_ignores_a_key_outside_the_offering
    get refresh_dashboard_widgets_path(keys: %w[payroll_secrets project_progress]),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_equal 1, response.body.scan("<turbo-stream").size
    refute_includes response.body, "payroll_secrets"
  end

  def test_update_picker_chooses_membership_and_drops_unauthorized_keys
    patch dashboard_widgets_path, params: {
      widget_keys: [ "overdue_tasks", "recent_movies", "totally_made_up_widget" ]
    }
    assert_response :redirect

    assert_equal %w[overdue_tasks recent_movies], store.stored_keys
  end

  # THE PICKER PAGE IS BALI'S. This app ships no `edit.html.erb`, so a 200 with
  # the engine's copy on it is the whole "include it and you have a dashboard"
  # promise being kept.
  def test_the_picker_renders_balis_own_template
    get edit_dashboard_widgets_path

    assert_response :success
    assert_select "input[name='widget_keys[]']", count: offering.size
    assert_includes response.body, I18n.t("bali_view.widgets.picker.unchecking_all")
  end

  # And the OTHER half of the view contract: this app does ship `show.html.erb`,
  # so its own page header wins over the engine's bare grid.
  def test_the_dashboard_page_prefers_this_apps_own_template
    get dashboard_widgets_path

    assert_response :success
    assert_select "p", text: /Your own arrangement/
  end

  # `create` is "make the defaults mine" — the arrangement stops being a
  # fallback and becomes rows the user can drag, and the page comes back in
  # edit mode.
  def test_create_adopts_the_defaults_and_returns_in_edit_mode
    assert_empty store.stored_keys

    post dashboard_widgets_path

    assert_redirected_to dashboard_widgets_path(editing: 1)
    assert_equal offering.map(&:key), store.stored_keys
  end

  # And leaves an existing arrangement alone, so a second press cannot flatten
  # a layout back to catalog order.
  def test_create_does_not_disturb_an_existing_arrangement
    patch arrange_dashboard_widgets_path, params: { widgets: [ { key: "recent_movies", size: "large" } ] }

    post dashboard_widgets_path

    assert_equal %w[recent_movies], store.stored_keys
  end

  def test_reset_drops_every_row
    patch arrange_dashboard_widgets_path, params: { widgets: [ { key: "overdue_tasks", size: "" } ] }
    assert_equal %w[overdue_tasks], store.stored_keys

    delete dashboard_widgets_path
    assert_response :redirect

    assert_empty store.stored_keys
  end
end
