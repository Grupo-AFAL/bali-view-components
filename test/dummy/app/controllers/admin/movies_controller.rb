# frozen_string_literal: true

module Admin
  class MoviesController < BaseController
    before_action :set_movie, only: %i[show edit update destroy]

    def index
      # `Bali::Filterable#filter_form` closes the persistence loop (#999):
      # `context:` comes from `Bali.filter_context` (see config/initializers/bali.rb) and
      # `persist_enabled:` from the `bali_persist_admin_movies` cookie the toggle writes —
      # the two kwargs that used to be passed by hand here, with the cookie's format leaking
      # into the host. `storage_id:` goes explicit because this listing already had a
      # published identity ('admin_movies', with an underscore); derived from the controller
      # it would be 'admin-movies'.
      @filter_form = filter_form(
        Bali::FilterForm,
        Movie.all,
        # `studio_name` and not `tenant_name`: `alias_method :tenant, :studio` is a Ruby
        # method Ransack does not see, and an invalid field inside a combined predicate makes
        # Ransack discard the WHOLE condition without raising anything — the quick search
        # returned all 20 movies for any text.
        search_fields: %i[name genre studio_name],
        storage_id: "admin_movies",
        # The "Group by" control auto-configures from here: this page is the end-to-end
        # reference of the canonical index, so it has to exercise the family of controls, not
        # just describe it. The THREE shapes Ransack knows how to sort —and which since #1102
        # also group— are represented: columns (`genre`, `status`), a `ransacker`
        # (`budget_band`, a SQL CASE with its twin in Ruby) and an association path, which
        # needs `value:` because `movie.studio_name` does not exist.
        group_by_attributes: [
          :genre,
          :status,
          { attribute: :budget_band, label: "Budget" },
          { attribute: :studio_name, label: "Studio", value: ->(movie) { movie.studio&.name } }
        ],
        # The engine's default store (bali_saved_views table). The owner goes explicit
        # because the FilterForm lives in the host; the mutations are resolved by the
        # engine's controller through `Bali.saved_views_owner` (see
        # config/initializers/bali.rb).
        saved_views_store: :default,
        saved_views_owner: current_user
      )
      @pagy, @movies = pagy(@filter_form.result.includes(:studio), limit: 10)

      respond_to do |format|
        format.html
        format.turbo_stream
        # Without this the export link is a 406 and there is no way to see that the active
        # filtering travelled with it.
        format.csv do
          render plain: @filter_form.result.pluck(:name).join("\n"), content_type: "text/csv"
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
        redirect_to admin_movie_path(@movie), notice: "Movie was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @movie.update(movie_params)
        redirect_to admin_movie_path(@movie), notice: "Movie was successfully updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @movie.destroy
      redirect_to admin_movies_url, notice: "Movie was successfully deleted."
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
