# frozen_string_literal: true

require "test_helper"

# The component tests pin `context:` against a stubbed request; this pins the whole chain the
# dummy migration actually walks — Bali::LayoutConcern turning `?layout=false` into a
# layout-less response AND into the `drawer_request?` the page component autodetects from —
# over the four views that lost their `if params[:layout] == 'false'`.
class PageContextRequestTest < ActionDispatch::IntegrationTest
  def setup
    @studio = Studio.create!(name: "Test Studio", country: "Mexico", status: :active)
  end

  def test_form_page_view_serves_a_full_page
    get new_admin_studio_path

    assert_response :ok
    assert_select "body"                       # the layout is there
    assert_select ".form-page-component .card" # ... and so is the Card
    assert_select ".breadcrumbs"
    assert_select ".back-button[href=?]", admin_studios_path
  end

  def test_the_same_view_serves_a_drawer_without_chrome
    get new_admin_studio_path, params: { layout: "false" }

    assert_response :ok
    assert_select "body", false, "the drawer fetch must not carry a layout"
    assert_select ".form-page-component"
    assert_select ".form-page-component .card", false
    assert_select ".breadcrumbs", false
    assert_select ".back-button", false
    assert_select "form[action=?]", admin_studios_path
  end

  def test_edit_serves_both_contexts
    get edit_admin_studio_path(@studio)
    assert_response :ok
    assert_select ".form-page-component .card"
    assert_select ".back-button"

    get edit_admin_studio_path(@studio), params: { layout: "false" }
    assert_response :ok
    assert_select ".form-page-component .card", false
    assert_select ".back-button", false
  end

  def test_show_page_view_serves_both_contexts
    get admin_studio_path(@studio)
    assert_response :ok
    assert_select ".show-page-component"
    assert_select ".back-button[href=?]", admin_studios_path

    get admin_studio_path(@studio), params: { layout: "false" }
    assert_response :ok
    assert_select "body", false
    assert_select ".show-page-component"
    assert_select ".back-button", false
  end

  # The Cancel button is the one thing `context:` deliberately does not absorb: it closes the
  # overlay in a drawer and navigates on a page. The context still reaches the partial from
  # the component (`drawer: page.drawer?`) rather than from `params`.
  def test_cancel_closes_the_drawer_and_navigates_on_a_page
    get new_admin_studio_path
    assert_response :ok
    assert_select "a[href=?]", admin_studios_path, text: "Cancel"

    get new_admin_studio_path, params: { layout: "false" }
    assert_response :ok
    assert_select "button[data-action='drawer#close']", text: "Cancel"
  end
end
