# frozen_string_literal: true

class Document < ApplicationRecord
  # The signature book comes from the engine (#709): `acknowledgments`, `acknowledge(user:)`
  # and `acknowledged_by?` come from here. There is no macro to configure.
  include Bali::Acknowledgeable

  # Virtual on purpose, with no column: `Bali::Acknowledgeable` only asks for
  # `version_label` through `try`, so it is enough that the model responds. It is the label
  # people are shown ("1.0"), and changing it turns the next acknowledgment into a new
  # signature. Same default as gobierno-corporativo's `version_number`.
  attribute :version_label, :string, default: "1.0"

  # #708 — materializes the references embedded in `content` on save. The dummy declares the
  # referenceable types in config/initializers/bali.rb.
  include Bali::EntityReferenceable

  # The history comes from the engine (#707): `content_versions`, `create_version!`,
  # `create_or_coalesce_version!` and `restore_content_version!` come from here. This app
  # had its own `DocumentVersion` with the same pair of methods —without `with_lock`, which
  # was the bug— and adopting the concern is what proves the engine works for a host.
  include Bali::ContentVersionable
  content_versionable attribute: :content, coalesce_window: 5.minutes

  enum :status, { draft: 0, published: 1, archived: 2 }
  # #706 — the engine owns the threads now. A host only needs this association to
  # clean up after itself; the editor never goes through it (it reads the engine's
  # endpoints, scoped by `commentable_type`/`commentable_id`).
  has_many :comment_threads, as: :commentable, class_name: "Bali::BlockEditorThread", dependent: :destroy
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
