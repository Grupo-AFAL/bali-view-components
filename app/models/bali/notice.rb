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
          unless EMAIL_MODES.include?(options[:email])
            raise ArgumentError, "Bali.notice_kinds[:#{name}]: email: must be nil, :immediate " \
                                 "or :digest, not #{options[:email].inspect}"
          end

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

    def announce
      Bali::NoticeDeliveryJob.enqueue(delivery) if delivery&.mode == "immediate"
      Bali::Inbox::Badge.refresh(recipient)
    end
  end
end
