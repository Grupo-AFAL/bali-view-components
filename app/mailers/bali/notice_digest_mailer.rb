# frozen_string_literal: true

module Bali
  # #1512 — one email with every :digest notice a recipient got since the last run. It inherits
  # the host's mailer (`Bali.notices_parent_mailer`), so it carries the host's layout and sender.
  class NoticeDigestMailer < Bali.notices_parent_mailer.constantize
    class MissingRecipientEmail < StandardError; end

    # A kind with fewer notices than this goes into the shared «Otros avisos» block.
    GROUP_MIN = 3
    LISTED_PER_GROUP = 3

    Group = Data.define(:label, :notices)

    helper_method :absolute_url

    def digest(recipient, notices)
      email = recipient.try(:email)
      raise MissingRecipientEmail, "#{recipient.class} ##{recipient.id} has no email" if email.blank?

      @notices = notices.sort_by(&:created_at)
      @groups = groups_of(@notices)
      @heading = heading_for(recipient, @notices.size)
      @window = window_of(@notices.first.created_at, @notices.last.created_at)
      @app_name = t("bali_view.notices.digest.app_name",
                    default: Rails.application.class.module_parent_name.titleize)

      mail to: email, subject: t("bali_view.notices.digest.subject", count: @notices.size, app: @app_name)
    end

    private

    def groups_of(notices)
      by_kind = notices.group_by(&:kind)
      own, rest = by_kind.partition { |_kind, kind_notices| kind_notices.size >= GROUP_MIN }

      groups = own.map { |kind, kind_notices| Group.new(label: kind_label(kind), notices: kind_notices) }
      groups << Group.new(label: t("bali_view.notices.digest.others"), notices: rest.flat_map(&:last)) if rest.any?
      groups
    end

    def heading_for(recipient, count)
      name = recipient.try(:first_name).presence || recipient.try(:name).presence
      return t("bali_view.notices.digest.heading_no_name", count: count) if name.nil?

      t("bali_view.notices.digest.heading", count: count, name: name)
    end

    def window_of(first, last)
      day = t("bali_view.notices.digest.day_format")
      return t("bali_view.notices.digest.window_days", from: l(first, format: "#{day}, %H:%M"),
                                                      to: l(last, format: "#{day}, %H:%M")) if first.to_date != last.to_date

      t("bali_view.notices.digest.window", day: l(first, format: day), from: l(first, format: "%H:%M"),
                                           to: l(last, format: "%H:%M"))
    end

    def kind_label(kind)
      t("bali_view.notices.digest.kinds.#{kind}", default: kind.humanize)
    end

    def absolute_url(path)
      return path if path.blank? || path.match?(%r{\A[a-z][a-z0-9+.-]*://}i)

      URI.join(main_app.root_url, path).to_s
    end
  end
end
