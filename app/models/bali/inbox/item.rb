# frozen_string_literal: true

module Bali
  module Inbox
    # One thing waiting on someone. `record` is what it is about, and `kind` + its GlobalID is
    # its address (`/inbox/items/:kind/:gid`).
    Item = Data.define(:kind, :record, :title, :subtitle, :href, :due_at, :requested_by, :module_key) do
      def initialize(kind:, record:, title:, subtitle: nil, href: nil, due_at: nil, requested_by: nil,
                     module_key: nil)
        super
      end

      def gid = record.to_gid_param

      # «Vencidos», «Esta semana», «Después». A date is due at the end of its day.
      def band(now = Time.current)
        return :later if due_at.nil?
        return :overdue if due_time < now

        due_time <= now + 7.days ? :this_week : :later
      end

      def overdue?(now = Time.current) = band(now) == :overdue

      def due_time
        due_at.is_a?(Date) && !due_at.is_a?(DateTime) ? due_at.in_time_zone.end_of_day : due_at&.in_time_zone
      end
    end
  end
end
