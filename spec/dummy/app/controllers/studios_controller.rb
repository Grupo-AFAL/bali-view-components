# frozen_string_literal: true

class StudiosController < ApplicationController
  # Pagy::Method is included in ApplicationController (Pagy 43+)
  before_action :set_studio, only: %i[show edit update destroy]

  def index
    load_listing

    respond_to do |format|
      format.html
      # Sin esto el link de export del ⋯ es un 406 y no hay forma de ver que el recorte viajó.
      format.csv do
        render plain: @filter_form.result.pluck(:name).join("\n"), content_type: 'text/csv'
      end
    end
  end

  def show; end

  def new
    @studio = Studio.new
  end

  def edit; end

  # El éxito responde por los dos caminos a propósito. Desde la página, un redirect. Desde el
  # drawer, un `text/vnd.turbo-stream.html`: el ModalController aplica los streams Y cierra el
  # panel, que es lo que un redirect no puede hacer — se lleva la página entera con él. El
  # error NO se ramifica: `render :new` devuelve HTML, el drawer lo mete en su propio cuerpo y
  # el formulario se re-pinta adentro con sus mensajes.
  def create
    @studio = Studio.new(studio_params)

    if @studio.save
      respond_to do |format|
        format.html { redirect_to studios_path, notice: 'Studio was successfully created.' }
        format.turbo_stream { load_listing }
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @studio.update(studio_params)
      respond_to do |format|
        format.html { redirect_to studios_path, notice: 'Studio was successfully updated.' }
        # La misma plantilla que create: el nodo que se reemplaza es el mismo, y dos copias
        # de un stream que apunta al mismo id divergen en silencio.
        format.turbo_stream do
          load_listing
          render :create
        end
      end
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @studio.destroy
    redirect_to studios_url, notice: 'Studio was successfully deleted.'
  end

  private

  def set_studio
    @studio = Studio.find(params[:id])
  end

  def studio_params
    params.expect(studio: %i[name country status size founded_year indie])
  end

  # El listado, en un solo lugar: lo arma `index` y lo vuelve a armar el stream de
  # create/update, porque el nodo que el drawer reemplaza es el mismo.
  def load_listing
    @filter_form = Bali::FilterForm.new(
      Studio.all,
      params,
      simple_filters: Studio.filter_options,
      search_fields: %i[name],
      search_icon: 'search',
      # Un listado sin `storage_id` no tiene identidad: la persistencia de filtros y el
      # marcador de la toolbar se apagan solos, en silencio. Es el mínimo que necesita
      # cualquier índice, adopte o no las vistas guardadas y el selector de columnas.
      storage_id: 'studios',
      # Sin `context:` la caché de persistencia es UNA sola para todo el proceso (ver
      # ApplicationController#filter_context): dos visitantes se pisan los filtros.
      context: filter_context,
      persist_enabled: cookies['bali_persist_studios'] == '1'
    )

    # `.order(:name)` se apendea DESPUÉS del orden de Ransack, así que un clic en un
    # encabezado sigue mandando; esto solo fija el desempate.
    @pagy, @studios = pagy(@filter_form.result.order(:name), items: 10)
  end
end
