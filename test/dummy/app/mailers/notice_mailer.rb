# frozen_string_literal: true

# The dummy's `Bali.notices_mailer`: the one email a host writes for an :immediate notice.
class NoticeMailer < ApplicationMailer
  class MissingRecipientEmail < StandardError; end

  def notify(notice)
    @notice = notice
    email = notice.recipient.try(:email)
    raise MissingRecipientEmail, "#{notice.recipient.class} ##{notice.recipient.id} has no email" if email.blank?

    mail to: email, subject: notice.message
  end
end
