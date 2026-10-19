# frozen_string_literal: true

require "test_helper"

# #1512 — what the digest says: one block per kind with enough notices, the rest together, and
# links that never go through an endpoint that marks a notice read.
class BaliNoticeDigestMailerTest < ActionMailer::TestCase
  def setup
    @kinds = Bali.notice_kinds
    Bali.notice_kinds = { movie_review: { email: :digest }, movie_cast: { email: :digest },
                          movie_poster: { email: :digest } }
    @ana = User.create!(name: "Ana")
    @movie = Tenant.create!(name: "Studio").movies.create!(name: "Alien", status: 0)
  end

  def teardown
    Bali.notice_kinds = @kinds
  end

  def notices(kind, count)
    Array.new(count) do |n|
      @movie.notify(recipient: @ana, kind: kind, message: "#{kind} #{n + 1}", action_url: "/movies/#{n + 1}")
    end
  end

  def digest(notices)
    I18n.with_locale(:es) { Bali::NoticeDigestMailer.digest(@ana, notices).message }
  end

  def body(mail) = mail.text_part.body.to_s

  def test_the_subject_counts_the_notices
    mail = digest(notices(:movie_review, 4))

    assert_equal "4 avisos nuevos en Dummy", mail.subject
    assert_equal [ "ana@example.com" ], mail.to
  end

  def test_kinds_with_three_or_more_get_their_own_block_and_the_rest_share_otros_avisos
    text = body(digest(notices(:movie_review, 3) + notices(:movie_cast, 1) + notices(:movie_poster, 1)))

    assert_match(/Movie review · 3/, text)
    assert_match(/Otros avisos · 2/, text)
    refute_match(/Movie cast · 1/, text)
  end

  def test_lists_the_first_three_of_a_kind_and_the_remainder
    text = body(digest(notices(:movie_review, 5)))

    assert_match "movie_review 3", text
    refute_match "movie_review 4", text
    assert_match "y 2 más en tu bandeja", text
  end

  def test_rows_link_to_the_absolute_action_url_never_an_engine_path
    mail = digest(notices(:movie_review, 1))

    assert_match "http://example.com/movies/1", mail.html_part.body.to_s
    refute_match "/inbox/notices/", mail.html_part.body.to_s
  end

  def test_the_button_opens_the_notices_tab
    assert_match "http://example.com/inbox?tab=notices", digest(notices(:movie_review, 1)).html_part.body.to_s
  end
end
