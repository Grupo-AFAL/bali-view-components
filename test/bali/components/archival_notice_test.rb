# frozen_string_literal: true

require "test_helper"

class BaliArchivalNoticeComponentTest < ComponentTestCase
  def setup
    studio = Tenant.create!(name: "Studio")
    @movie = studio.movies.create!(name: "Blade Runner", status: 0)
    @remake = studio.movies.create!(name: "Blade Runner 2049", status: 0)
    @ana = User.create!(name: "Ana")
  end

  def test_renders_nothing_for_a_record_that_is_not_archived
    render_inline(Bali::ArchivalNotice::Component.new(record: @movie))

    assert_no_selector ".archival-notice-component"
  end

  def test_says_when_who_why_and_what_replaces_it
    archive_on_october_third(by: @ana, reason: :replaced, successor: @remake)
    render_inline(Bali::ArchivalNotice::Component.new(record: @movie, successor_url: "/movies/#{@remake.id}"))

    assert_selector ".archival-notice-component.alert.alert-warning",
                    text: "Archived on October 03, 2026 by Ana. Reason: Replaced by another. Replaced by"
    assert_link "Blade Runner 2049", href: "/movies/#{@remake.id}"
  end

  def test_names_the_successor_without_a_link_when_no_url_is_given
    archive_on_october_third(reason: :replaced, successor: @remake)
    render_inline(Bali::ArchivalNotice::Component.new(record: @movie))

    assert_text "Replaced by Blade Runner 2049."
    assert_no_selector ".archival-notice-component a"
  end

  def test_leaves_out_what_was_not_recorded
    archive_on_october_third
    render_inline(Bali::ArchivalNotice::Component.new(record: @movie))

    assert_selector ".archival-notice-component p", exact_text: "Archived on October 03, 2026."
  end

  def test_reopen_appears_only_with_an_unarchive_url
    @movie.archive!(by: @ana)

    with_request_url("/admin/movies") { render_inline(Bali::ArchivalNotice::Component.new(record: @movie)) }
    assert_no_button "Reopen"

    with_request_url("/admin/movies") do
      render_inline(Bali::ArchivalNotice::Component.new(record: @movie, unarchive_url: "/bali/archivals/unarchive"))
    end
    assert_selector "form[action='/bali/archivals/unarchive'][method=post] button[type=submit]", text: "Reopen"
  end

  def test_a_reopened_record_shows_no_notice
    @movie.archive!(by: @ana)
    @movie.unarchive!(by: @ana)
    render_inline(Bali::ArchivalNotice::Component.new(record: @movie))

    assert_no_selector ".archival-notice-component"
  end

  def test_reads_as_the_spec_wrote_it_in_spanish
    archive_on_october_third(by: @ana, reason: :replaced, successor: @remake)
    I18n.with_locale(:es) { render_inline(Bali::ArchivalNotice::Component.new(record: @movie)) }

    assert_text "Dado de baja el 03 de Octubre de 2026 por Ana. Motivo: Reemplazado por otro. " \
                "Lo sustituye Blade Runner 2049."
  end

  def test_options_reach_the_alert
    @movie.archive!
    render_inline(Bali::ArchivalNotice::Component.new(record: @movie, class: "mt-4", data: { hook: "" }))

    assert_selector ".archival-notice-component.mt-4[data-hook]"
  end

  private

  def archive_on_october_third(**archival)
    travel_to(Time.zone.local(2026, 10, 3, 9)) { @movie.archive!(**archival) }
  end
end
