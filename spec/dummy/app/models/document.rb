# frozen_string_literal: true

class Document < ApplicationRecord
  # El historial lo pone el engine (#707): `content_versions`, `create_version!`,
  # `create_or_coalesce_version!` y `restore_content_version!` vienen de aquí. Esta app
  # tenía su propio `DocumentVersion` con la misma pareja de métodos —sin `with_lock`, que
  # era el bug— y adoptar el concern es lo que prueba que el engine sirve para un host.
  include Bali::ContentVersionable
  content_versionable attribute: :content, coalesce_window: 5.minutes

  enum :status, { draft: 0, published: 1, archived: 2 }
  has_many :block_editor_threads, dependent: :destroy
  validates :title, presence: true
  validates :author_name, presence: true

  def word_count
    return 0 if content.blank?
    extract_text(content).split(/\s+/).reject(&:blank?).size
  end

  private

  def extract_text(blocks)
    return "" unless blocks.is_a?(Array)
    blocks.filter_map do |block|
      texts = []
      texts << extract_inline_content(block["content"]) if block["content"]
      texts << extract_text(block["children"]) if block["children"]
      texts.join(" ")
    end.join(" ")
  end

  def extract_inline_content(content)
    return "" unless content.is_a?(Array)
    content.filter_map { |item| item["text"] }.join(" ")
  end
end
