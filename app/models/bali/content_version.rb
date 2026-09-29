# frozen_string_literal: true

module Bali
  # #707 — one version of the content of ANY host model (polymorphic `record`). It is not
  # created by hand: the versioned model produces it through `Bali::ContentVersionable`
  # (`create_version!` / `create_or_coalesce_version!`), which is what knows the versioned
  # attribute and does the numbering.
  #
  # `author` is optional and `author_name` required on purpose: the JSON that
  # `document_editor/index.js` reads only serves `author_name`, so a host with no user model
  # leaves the FK nil without losing any of the UI.
  class ContentVersion < ApplicationRecord
    belongs_to :record, polymorphic: true
    belongs_to :author, polymorphic: true, optional: true

    # ActiveStorage is still optional in the engine: a host that does not load it has no
    # `has_one_attached` defined and the whole model would fail to autoload. No presence
    # validation — the column exists for the "version of a file" case (gc's content_kind),
    # not to require it.
    has_one_attached :file if respond_to?(:has_one_attached)

    # The same limit as the column. Being on both sides is deliberate: the validation turns
    # an overlong summary into a model error the host can show, and the column holds it even
    # when someone writes around the model.
    SUMMARY_MAX_LENGTH = 255

    validates :version_number, presence: true,
                               uniqueness: { scope: %i[record_type record_id] }
    validates :author_name, presence: true
    validates :summary, length: { maximum: SUMMARY_MAX_LENGTH }, allow_nil: true

    # `reorder`, not `order`: the `content_versions` association already orders ascending
    # and a chained `order` STACKS behind it, so the first clause would still win and this
    # would return the oldest version — which is just the one the coalescing compares with.
    scope :newest_first, -> { reorder(version_number: :desc) }

    # The same author across two consecutive versions: by FK when either side has one, by
    # name when the host has no user model. The coalescing uses it. It reads `author_id`,
    # not `author`, so as not to load the record just to compare it.
    def same_author?(other_author, other_author_name)
      return author_name == other_author_name if author_id.nil? && other_author.nil?

      other_author.present? &&
        author_type == other_author.class.polymorphic_name &&
        author_id == other_author.id
    end
  end
end
