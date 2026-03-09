# frozen_string_literal: true

class DocumentVersion < ApplicationRecord
  belongs_to :document
  validates :version_number, presence: true, uniqueness: { scope: :document_id }
  validates :author_name, presence: true
end
