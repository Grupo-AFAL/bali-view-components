# frozen_string_literal: true

module Bali
  # The inbox's views (#1512), rendered by the host's controller through
  # Bali::Concerns::Controllers::Inbox, which adds this helper to it.
  module InboxHelper
    def inbox_kind_label(kind, count: 1)
      t("bali_view.inbox.kinds.#{kind}", count: count, default: kind.to_s.humanize)
    end

    def inbox_module_label(module_key)
      t("bali_view.inbox.modules.#{module_key}", default: module_key.to_s.humanize)
    end

    def inbox_band_label(band) = t("bali_view.inbox.bands.#{band}")

    def inbox_band_color(band) = { overdue: "text-soft-error", this_week: "text-soft-warning" }.fetch(band, "text-base-content/70")

    # One address per item, shared by the list's selection and the detail's frame.
    def inbox_item_key(item) = "#{item.kind}-#{item.gid}"

    def inbox_item_url(item) = url_for(action: :item, kind: item.kind, gid: item.gid)

    def inbox_open_item_url(item) = url_for(action: :open_item, kind: item.kind, gid: item.gid)

    def inbox_item_icon(item) = inbox_query.icon(item.kind)

    def inbox_fresh?(item, fresh) = fresh.include?([ item.record.class.polymorphic_name, item.record.id ])

    def inbox_count(count) = Bali::Topbar::Inbox::Component.count_text(count)

    # The «Avisos» pill counts only the unread ones; a screen reader hears that.
    def inbox_unread_count(count)
      safe_join([ inbox_count(count), tag.span(" #{t("bali_view.inbox.notices.unread")}", class: "sr-only") ])
    end

    # «venció hace 2 días», «vence hoy», «vence el viernes», «vence el 30 nov.», «sin fecha».
    def inbox_due_text(item, now = Time.current)
      due = item.due_time
      return t("bali_view.inbox.due.none") if due.nil?
      return t("bali_view.inbox.due.overdue", time: time_ago_in_words(due)) if due < now
      return t("bali_view.inbox.due.today") if due.to_date == now.to_date
      return t("bali_view.inbox.due.on", day: l(due.to_date, format: "%A")) if item.band(now) == :this_week

      t("bali_view.inbox.due.on", day: l(due.to_date, format: :short))
    end

    def inbox_notice_time(notice)
      t("bali_view.inbox.notices.ago", time: time_ago_in_words(notice.created_at))
    end
  end
end
