# frozen_string_literal: true

module Admin
  class StudiosController < BaseController
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
    #
    # La rama del stream NO arma el listado: el POST del drawer no lleva los params de la página
    # (ver create.turbo_stream.erb), así que armarlo acá lo devuelve sin agrupar y sin recortar.
    # La plantilla pide un refresh y el listado lo vuelve a armar `index`, desde la URL real.
    def create
      @studio = Studio.new(studio_params)

      if @studio.save
        respond_to do |format|
          format.html { redirect_to admin_studios_path, notice: 'Studio was successfully created.' }
          format.turbo_stream
        end
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @studio.update(studio_params)
        respond_to do |format|
          format.html { redirect_to admin_studios_path, notice: 'Studio was successfully updated.' }
          # La misma plantilla que create: los dos hacen lo mismo, y dos copias de un refresh
          # divergen en silencio.
          format.turbo_stream { render :create }
        end
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @studio.destroy
      redirect_to admin_studios_url, notice: 'Studio was successfully deleted.'
    end

    private

    def set_studio
      @studio = Studio.find(params[:id])
    end

    def studio_params
      params.expect(studio: %i[name country status size founded_year indie])
    end

    # El listado, en un solo lugar: lo arma `index` y lo pinta el partial que comparten la
    # página y el refresh del drawer.
    def load_listing
      # `Bali::Filterable#filter_form` (#999): context y persist_enabled derivados — ver el
      # comentario gemelo en Admin::MoviesController#index.
      @filter_form = filter_form(
        Bali::FilterForm,
        Studio.all,
        simple_filters: Studio.filter_options,
        search_fields: %i[name],
        search_icon: 'search',
        # Un listado sin `storage_id` no tiene identidad: la persistencia de filtros y el
        # marcador de la toolbar se apagan solos, en silencio. Es el mínimo que necesita
        # cualquier índice, adopte o no las vistas guardadas y el selector de columnas.
        storage_id: 'admin_studios',
        # El control "Agrupar por" se auto-configura desde acá. Es la lista blanca: el param
        # crudo nunca llega a un `group()` sin pasar por ella.
        group_by_attributes: %i[status country size],
        # Storage default del engine (tabla bali_saved_views). El dueño va explícito porque el
        # FilterForm vive en el host; las mutaciones las resuelve el controller del engine por
        # `Bali.saved_views_owner` (ver config/initializers/bali.rb).
        saved_views_store: :default,
        saved_views_owner: current_user
      )

      # `.order(:name)` se apendea DESPUÉS del orden de Ransack, así que un clic en un
      # encabezado sigue mandando; esto solo fija el desempate.
      @pagy, @studios = pagy(@filter_form.result.order(:name), limit: 10)
    end
  end
end
