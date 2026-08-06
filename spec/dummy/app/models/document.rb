# frozen_string_literal: true

class Document < ApplicationRecord
  # El libro de firmas lo pone el engine (#709): `acknowledgments`, `acknowledge(user:)` y
  # `acknowledged_by?` vienen de aquí. No hay macro que configurar.
  include Bali::Acknowledgeable

  # Virtual a propósito, sin columna: `Bali::Acknowledgeable` solo pregunta por
  # `version_label` con `try`, así que basta con que el modelo responda. Es la etiqueta que
  # se le enseña a la gente ("1.0"), y cambiarla convierte la siguiente confirmación en una
  # firma nueva. Mismo default que el `version_number` de gobierno-corporativo.
  attribute :version_label, :string, default: '1.0'

  enum :status, { draft: 0, published: 1, archived: 2 }
  has_many :document_versions, dependent: :destroy
  has_many :block_editor_threads, dependent: :destroy
  validates :title, presence: true
  validates :author_name, presence: true

  def current_version_number
    document_versions.maximum(:version_number) || 0
  end

  def create_version!(author_name:, summary: nil)
    document_versions.create!(
      content: content,
      version_number: current_version_number + 1,
      author_name: author_name,
      summary: summary
    )
  end

  def create_or_coalesce_version!(author_name:, summary: nil)
    last_version = document_versions.order(created_at: :desc).first
    if last_version && last_version.author_name == author_name && last_version.created_at > 5.minutes.ago
      last_version.update!(content: content, summary: summary)
      last_version
    else
      create_version!(author_name: author_name, summary: summary)
    end
  end

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
