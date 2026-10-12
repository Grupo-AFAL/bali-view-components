# frozen_string_literal: true

require "test_helper"

class BaliArchivalFormComponentTest < ComponentTestCase
  include ArchivableDeclaration

  def setup
    studio = Tenant.create!(name: "Studio")
    @movie = studio.movies.create!(name: "Blade Runner", status: 0)
    @remake = studio.movies.create!(name: "Blade Runner 2049", status: 0)
  end

  def test_offers_every_reason_with_its_label
    render_form

    Bali::Archivable::DEFAULT_REASONS.each do |reason|
      assert_selector "input[type=radio][name='archival[reason]'][value='#{reason}']"
    end
    assert_selector "label", text: "Replaced by another"
  end

  def test_the_successor_is_revealed_by_radio_toggle_for_the_reasons_that_need_one
    render_form

    assert_selector "form[data-controller='radio-toggle'][data-radio-toggle-disable-hidden-value='true']"
    assert_selector "input[name='archival[reason]'][data-action*='radio-toggle#change']", count: 5
    assert_selector "fieldset[data-radio-toggle-target='element'][data-radio-toggle-value='replaced'] " \
                    "select[name='archival[successor_id]'] option[value='#{@remake.id}']",
                    text: "Blade Runner 2049"
  end

  def test_several_reasons_that_need_a_successor_reach_radio_toggle_as_a_comma_list
    with_archivable(successor_required_for: %i[replaced superseded]) do
      render_form
    end

    assert_selector "fieldset[data-radio-toggle-target='element'][data-radio-toggle-value='replaced,superseded']"
  end

  def test_without_candidates_neither_the_successor_nor_its_reasons_are_offered
    [ Movie.none, nil ].each do |successors|
      render_form(successors: successors)

      assert_no_selector "input[name='archival[reason]'][value='replaced']"
      assert_no_selector "select[name='archival[successor_id]']"
      assert_selector "input[name='archival[reason]']", count: 4
    end
  end

  def test_without_a_successor_reason_the_successor_is_not_offered_even_with_candidates
    with_archivable(successor_required_for: []) do
      render_form
    end

    assert_no_selector "select[name='archival[successor_id]']"
    assert_selector "input[name='archival[reason]']", count: 5
  end

  def test_cancel_returns_to_return_to_and_still_closes_the_drawer
    render_form(return_to: "/admin/movies")

    assert_selector "a[href='/admin/movies'][data-action*='drawer#close']", text: "Cancel"
  end

  def test_cancel_is_a_drawer_button_without_return_to
    render_form

    assert_selector "button[type=button][data-action*='drawer#close']", text: "Cancel"
    assert_no_selector "a", text: "Cancel"
  end

  def test_return_to_travels_with_the_form
    render_form(return_to: "/admin/movies")

    assert_selector "input[type=hidden][name=return_to][value='/admin/movies']", visible: :all
  end

  def test_re_renders_an_invalid_archival_with_its_choice_and_its_error
    archival = Bali::Archival.new(archivable: @movie, reason: "replaced", note: "No successor yet")
    archival.validate
    render_form(archival: archival)

    assert_selector "input[name='archival[reason]'][value='replaced'][checked]"
    assert_selector "form[data-radio-toggle-current-value='replaced']"
    assert_selector "textarea[name='archival[note]'][maxlength='500']", text: "No successor yet"
    assert_selector "#archival_successor_id_error", text: "Successor can't be blank"
  end

  def test_submits_through_the_drawer
    render_form

    assert_selector "button[type=submit][data-action*='drawer#submit']"
  end

  private

  def render_form(successors: Movie.where.not(id: @movie.id), **options)
    render_inline(Bali::ArchivalForm::Component.new(
      record: @movie, successors: successors,
      url: "/bali/archivals?record_type=Movie&record_id=#{@movie.id}", **options
    ))
  end
end
