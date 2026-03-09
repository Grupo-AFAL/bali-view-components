# frozen_string_literal: true

class DocumentVersionsController < ApplicationController
  before_action :set_document

  def index
    versions = @document.document_versions.order(version_number: :desc)
    render json: versions.map { |v|
      {
        id: v.id,
        version_number: v.version_number,
        author_name: v.author_name,
        summary: v.summary,
        created_at: v.created_at.iso8601
      }
    }
  end

  def show
    version = @document.document_versions.find(params[:id])
    render json: {
      id: version.id,
      version_number: version.version_number,
      author_name: version.author_name,
      summary: version.summary,
      content: version.content,
      created_at: version.created_at.iso8601
    }
  end

  private

  def set_document
    @document = Document.find(params[:document_id])
  end
end
