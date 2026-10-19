# frozen_string_literal: true

module Bali
  # #1512 — what happened, stored for one recipient with its text. Its kind (`Bali.notice_kinds`)
  # decides whether it goes out by email and whether it announces an inbox item instead of
  # appearing in «Avisos».
  class Notice < ApplicationRecord
    EMAIL_MODES = [ nil, :immediate, :digest ].freeze

    Kind = Data.define(:name, :email, :queue, :announces)

    belongs_to :recipient, polymorphic: true
    belongs_to :actor, polymorphic: true, optional: true
    belongs_to :notifiable, polymorphic: true, optional: true
    has_one :delivery, class_name: "Bali::NoticeDelivery", dependent: :delete

    validates :kind, inclusion: { in: ->(_notice) { Bali::Notice.kinds.keys } }
    validates :message, presence: true

    scope :unread, -> { where(read_at: nil) }
    scope :recent, -> { order(created_at: :desc, id: :desc) }
    scope :addressed_to, ->(recipient) { where(recipient: recipient) }
    scope :listed, -> { where.not(kind: announcing_kinds) }

    after_create :record_delivery
    after_create_commit :announce

    class << self
      def kinds
        Bali.notice_kinds.to_h do |name, options|
          options = options.to_h
          check_email!(name, options[:email])

          [ name.to_s, Kind.new(name: name.to_s, email: options[:email], queue: options[:queue],
                                announces: options[:announces]&.to_sym) ]
        end
      end

      def kind(name) = kinds[name.to_s]

      def announcing_kinds = kinds.values.select(&:announces).map(&:name)

      def mark_all_read!(recipient)
        mark_read!(addressed_to(recipient)).tap { Bali::Inbox::Badge.expire(recipient) }
      end

      def mark_read!(notices)
        notices.unread.update_all(read_at: Time.current, updated_at: Time.current)
      end

      private

      def check_email!(name, email)
        unless EMAIL_MODES.include?(email)
          raise ArgumentError, "Bali.notice_kinds[:#{name}]: email: must be nil, :immediate or :digest, " \
                               "not #{email.inspect}"
        end
        return unless email == :immediate && Bali.notices_mailer.blank?

        raise ArgumentError, "Bali.notice_kinds[:#{name}] sends email: :immediate, which needs " \
                             "Bali.notices_mailer (the host mailer whose `notify(notice)` sends it)"
      end
    end

    def unread? = read_at.nil?

    def mark_read!
      return unless unread?

      update!(read_at: Time.current)
      Bali::Inbox::Badge.expire(recipient)
    end

    private

    # In the notice's own transaction, so a crash between the two can never leave a notice whose
    # email was silently dropped.
    def record_delivery
      mode = self.class.kind(kind)&.email
      return unless mode && Bali.notices_deliver_if.call(self)

      create_delivery!(mode: mode.to_s)
    end

    # After the commit, so neither may fail whoever wrote the notice, whose work is already saved:
    # the hourly sweep resends a delivery whose job never went in, and the cache is expired before
    # the broadcast, so only a page already open keeps its old number.
    def announce
      Rails.error.handle(context: { notice_id: id }) { Bali::NoticeDeliveryJob.enqueue(delivery) } if delivery&.mode == "immediate"
      Rails.error.handle(context: { notice_id: id }) { Bali::Inbox::Badge.refresh(recipient) }
    end
  end
end
