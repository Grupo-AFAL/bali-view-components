# frozen_string_literal: true

class DocumentsController < ApplicationController
  before_action :set_document, only: %i[show update destroy]

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
      @document.create_version!(author: author, author_name: author.name, summary: "Initial version")
      redirect_to document_path(@document), notice: "Document created."
    else
      render :new, status: :unprocessable_content
    end
  end

  # Crear la versión sigue siendo del HOST: el PATCH del autosave llega aquí, no al engine.
  # El engine solo lee el historial y lo restaura.
  def update
    if @document.update(document_params)
      @document.create_or_coalesce_version!(author: author, author_name: author.name)

      respond_to do |format|
        format.html { redirect_to document_path(@document), notice: "Document updated." }
        format.json { render json: { status: "ok", version: @document.current_content_version_number } }
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

  private

  def set_document
    @document = Document.find(params[:id])
  end

  # El autor de una versión es un REGISTRO, no un string: así se ejercita el FK polimórfico
  # opcional del engine. El `author_name` denormalizado sale del mismo usuario para que el
  # panel de historial y el topbar nombren a la misma persona.
  def author = User.demo

  def document_params
    params.expect(document: [ :title, :content, :status ])
  end
end
