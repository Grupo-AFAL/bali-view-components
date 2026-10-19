# frozen_string_literal: true

module Bali
  # /rails/mailers/bali/notice_digest_mailer/digest — the board «Correo agrupado»: one kind with its
  # own block and two that share «Otros avisos». Built in memory, so the preview writes nothing.
  class NoticeDigestMailerPreview < ActionMailer::Preview
    def digest
      start = Time.zone.parse("2026-10-17 10:40")
      reviews = %w[Alien Arrival Brazil Contact Dune Gattaca Her Inception Jaws Looper Moon Sunshine]
                .each_with_index.map do |title, n|
        notice(kind: "movie_review_requested", message: "#{title} is waiting for your review",
               at: start + (n * 4).minutes, path: "/admin/movies")
      end
      others = [
        notice(kind: "movie_released", message: "Luis approved the release of Blade Runner",
               at: start + 40.minutes, path: "/admin/movies"),
        notice(kind: "studio_created", message: "A new studio joined the catalog",
               at: start + 51.minutes, path: "/admin/studios")
      ]

      NoticeDigestMailer.digest(User.demo, reviews + others)
    end

    private

    def notice(kind:, message:, at:, path:)
      Bali::Notice.new(kind: kind, message: message, action_url: path, created_at: at)
    end
  end
end
