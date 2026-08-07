# frozen_string_literal: true

module Admin
  class MoviesController < BaseController
    before_action :set_movie, only: %i[show edit update destroy]

    def index
      @filter_form = Bali::FilterForm.new(
        Movie.all,
        params,
        # `studio_name` y no `tenant_name`: `alias_method :tenant, :studio` es un método Ruby
        # que Ransack no ve, y un campo inválido dentro de un predicado combinado hace que
        # Ransack descarte la condición ENTERA sin levantar nada — la búsqueda rápida
        # devolvía las 20 películas para cualquier texto.
        search_fields: %i[name genre studio_name],
        storage_id: 'admin_movies',
        # El control "Agrupar por" se auto-configura desde acá: esta página es la referencia
        # end-to-end del index canónico, así que tiene que ejercitar la familia de controles,
        # no solo describirla.
        group_by_attributes: %i[genre status],
        # Storage default del engine (tabla bali_saved_views). El dueño va explícito porque
        # el FilterForm vive en el host; las mutaciones las resuelve el controller del engine
        # por `Bali.saved_views_owner` (ver config/initializers/bali.rb).
        saved_views_store: :default,
        saved_views_owner: current_user,
        # Sin `context:` la caché de persistencia es UNA sola para todo el proceso (ver
        # ApplicationController#filter_context): dos visitantes se pisan los filtros.
        context: filter_context,
        persist_enabled: cookies['bali_persist_admin_movies'] == '1'
      )
      @pagy, @movies = pagy(@filter_form.result.includes(:studio), limit: 10)

      respond_to do |format|
        format.html
        format.turbo_stream
        # Sin esto el link de export es un 406 y no hay forma de ver que el recorte viajó.
        format.csv do
          render plain: @filter_form.result.pluck(:name).join("\n"), content_type: 'text/csv'
        end
      end
    end

    def show
      @characters = @movie.characters.positioned
      @related_movies = Movie.where(genre: @movie.genre).where.not(id: @movie.id).limit(4)
    end

    def new
      @movie = Movie.new
    end

    def edit; end

    def create
      @movie = Movie.new(movie_params)
      if @movie.save
        redirect_to admin_movie_path(@movie), notice: 'Movie was successfully created.'
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @movie.update(movie_params)
        redirect_to admin_movie_path(@movie), notice: 'Movie was successfully updated.'
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @movie.destroy
      redirect_to admin_movies_url, notice: 'Movie was successfully deleted.'
    end

    private

    def set_movie
      @movie = Movie.find(params[:id])
    end

    def movie_params
      params.expect(movie: %i[
        name genre status tenant_id indie
        synopsis rich_description release_date budget
        contact_email website_url time_zone rating poster
      ])
    end
  end
end
