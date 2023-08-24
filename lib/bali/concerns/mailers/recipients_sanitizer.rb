# frozen_string_literal: true

module Bali
  module Concerns
    module Mailers
      module RecipientsSanitizer
        # Remove inactive emails before sending the email
        def send_mail(to:, subject:, template: action_name, **options)
          recipients = sanitize_recipients(to)
          return if recipients.blank?

          mail(to: recipients, subject: subject, template: template, **options)
        end

        def sanitize_recipients(recipients)
          Array(recipients) - inactive_emails
        end

        def inactive_emails
          raise MethodNotImplemented
        end
      end
    end
  end
end
