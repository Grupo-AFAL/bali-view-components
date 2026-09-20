# frozen_string_literal: true

module Admin
  class StudiosController < BaseController
    before_action :set_studio, only: %i[show edit update destroy]

    def index
      load_listing

      respond_to do |format|
        format.html
        # Without this the export link in the ⋯ is a 406 and there is no way to see that the
        # active filtering travelled with it.
        format.csv do
          render plain: @filter_form.result.pluck(:name).join("\n"), content_type: "text/csv"
        end
      end
    end

    def show; end

    def new
      @studio = Studio.new
    end

    def edit; end

    # Success answers down both paths on purpose. From the page, a redirect. From the drawer, a
    # `text/vnd.turbo-stream.html`: the ModalController applies the streams AND closes the panel,
    # which is what a redirect cannot do — it takes the whole page with it. The error path does
    # NOT branch: `render :new` returns HTML, the drawer puts it in its own body and the form
    # re-paints inside it with its messages.
    #
    # The stream branch does NOT build the listing: the drawer's POST does not carry the page's
    # params (see create.turbo_stream.erb), so building it here returns it ungrouped and
    # unfiltered. The template asks for a refresh and `index` rebuilds the listing, from the
    # real URL.
    def create
      @studio = Studio.new(studio_params)

      if @studio.save
        respond_to do |format|
          format.html { redirect_to admin_studios_path, notice: "Studio was successfully created." }
          format.turbo_stream
        end
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @studio.update(studio_params)
        respond_to do |format|
          format.html { redirect_to admin_studios_path, notice: "Studio was successfully updated." }
          # The same template as create: both do the same thing, and two copies of a refresh
          # diverge silently.
          format.turbo_stream { render :create }
        end
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @studio.destroy
      redirect_to admin_studios_url, notice: "Studio was successfully deleted."
    end

    private

    def set_studio
      @studio = Studio.find(params[:id])
    end

    def studio_params
      params.expect(studio: %i[name country status size founded_year indie])
    end

    # The listing, in a single place: `index` builds it and it is painted by the partial the
    # page and the drawer's refresh share.
    def load_listing
      # `Bali::Filterable#filter_form` (#999): context and persist_enabled derived — see the
      # twin comment in Admin::MoviesController#index.
      @filter_form = filter_form(
        Bali::FilterForm,
        Studio.all,
        simple_filters: Studio.filter_options,
        search_fields: %i[name],
        search_icon: "search",
        # A listing with no `storage_id` has no identity: filter persistence and the
        # toolbar's marker turn themselves off, silently. It is the minimum any index needs,
        # whether or not it adopts saved views and the column selector.
        storage_id: "admin_studios",
        # The "Group by" control auto-configures from here. It is the allowlist: the raw
        # param never reaches a `group()` without going through it.
        group_by_attributes: %i[status country size],
        # The engine's default store (bali_saved_views table). The owner goes explicit because
        # the FilterForm lives in the host; the mutations are resolved by the engine's
        # controller through `Bali.saved_views_owner` (see config/initializers/bali.rb).
        saved_views_store: :default,
        saved_views_owner: current_user
      )

      # `.order(:name)` is appended AFTER Ransack's ordering, so a click on a header still
      # wins; this only settles the tie-break.
      @pagy, @studios = pagy(@filter_form.result.order(:name), limit: 10)
    end
  end
end
