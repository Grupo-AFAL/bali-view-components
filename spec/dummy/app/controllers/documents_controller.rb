# frozen_string_literal: true

class DocumentsController < ApplicationController
  before_action :set_document, only: %i[show update destroy restore_version]

  DEMO_USER = "Demo User"
  DEMO_USERS = [
    { id: "user-1", username: "Demo User" },
    { id: "user-2", username: "Jane Smith" },
    { id: "user-3", username: "Bob Wilson" }
  ].freeze

  def index
    @documents = Document.order(updated_at: :desc)
  end

  def show; end

  def new
    @document = Document.new
  end

  def create
    @document = Document.new(document_params)
    @document.author_name = DEMO_USER

    if @document.save
      @document.create_version!(author_name: DEMO_USER, summary: "Initial version")
      redirect_to document_path(@document), notice: "Document created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @document.update(document_params)
      @document.create_or_coalesce_version!(author_name: DEMO_USER)

      respond_to do |format|
        format.html { redirect_to document_path(@document), notice: "Document updated." }
        format.json { render json: { status: "ok", version: @document.current_version_number } }
      end
    else
      respond_to do |format|
        format.html { render :show, status: :unprocessable_content }
        format.json { render json: { errors: @document.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  def destroy
    @document.destroy
    redirect_to documents_path, notice: "Document deleted."
  end

  def restore_version
    version = @document.document_versions.find(params[:version_id])
    @document.create_version!(author_name: DEMO_USER, summary: "Before restore to v#{version.version_number}")
    @document.update!(content: version.content)
    @document.create_version!(author_name: DEMO_USER, summary: "Restored from v#{version.version_number}")

    respond_to do |format|
      format.html { redirect_to document_path(@document), notice: "Version restored." }
      format.json { render json: { status: "ok" } }
    end
  end

  private

  def set_document
    @document = Document.find(params[:id])
  end

  def document_params
    params.expect(document: [ :title, :content, :status ])
  end
end
