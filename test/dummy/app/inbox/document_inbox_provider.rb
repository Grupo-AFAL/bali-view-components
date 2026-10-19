# frozen_string_literal: true

# Published documents the person has not acknowledged yet (Bali::Acknowledgeable).
class DocumentInboxProvider
  include Bali::Inbox::Provider

  def kind = :acknowledgment

  def icon = "file-check"

  def pending_for(user)
    Document.published.where.not(
      id: Bali::Acknowledgment.where(acknowledgeable_type: "Document", user: user).select(:acknowledgeable_id)
    )
  end

  def build_item(document, user:)
    item document, title: document.title, subtitle: document.author_name, href: document_path(document)
  end
end
