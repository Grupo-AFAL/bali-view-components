# frozen_string_literal: true

# Reference wiring for Bali::SplitView (#728, #971, #977): the whole Rails side
# of a master-detail screen in one action. `?selected=<id>` is what makes the
# selection deep-linkable — the row links carry `data-turbo-frame`, so Turbo
# swaps only the detail pane, but the same URL loaded cold renders the full page
# with that row already highlighted.
#
# The listing is paginated and the component's infinite scroll fetches this very
# action one page further on. There is nothing here for it: no `respond_to`, no
# format branch, no endpoint of its own. That is the point of fetch-and-extract.
#
# Filtering is query params read straight off `params`. No FilterForm, no
# Ransack, no form object — the pills are links, so a filter is a URL, and the
# component builds those URLs itself from the current request. Nothing here
# resets the infinite scroll either: a pill click is a full-page navigation, so
# the server renders page one and the sentinel picks up a next-page URL that
# already carries the filter.
#
# `@selected` is looked up against the whole table and not the current page, so a
# deep link to a record on page 4 renders its detail immediately. Its row is not
# on screen to highlight yet — it lights up when infinite scroll reaches its page.
class SplitViewsController < ApplicationController
  PER_PAGE = 5
  # `:full`'s page one must be TALLER than its pane. Clamping under a long list
  # is precisely what the first version of bali#979 got wrong — `flex: 1 0 auto`
  # on the body container never came back down from the content's height, the
  # page scrolled as a whole and the pane scroll never engaged — and a short
  # page one is why this reference couldn't catch it: five rows fit the screen,
  # flex-grow stretched them, and everything looked right for a whole beta.
  # Twelve rows overflow the pane at 1280x800 AND leave a second page in the
  # table, so the sentinel keeps demonstrating infinite scroll inside the clamp.
  FULL_PER_PAGE = 12

  # AppLayout renders its own <body>, so the shell around it must not have one.
  #
  # NO como `layout "app_layout_preview", only: :full`: `only:`/`except:` genera un
  # `_conditional_layout?` DE INSTANCIA, y el `_layout` que Bali::LayoutConcern define en
  # ApplicationController llama a ese mismo método por dispatch dinámico. O sea que la
  # condición no solo elige el layout de `full` — apaga el concern entero para TODAS las
  # demás acciones, que caen a `layouts/application` sin pasar por `conditionally_skip_layout`.
  # Medido: con `only:`, `/split-view?layout=false` seguía trayendo el shell completo y una
  # request de Turbo Frame también. Un layout POR ACCIÓN se escribe acá, con `super`, porque
  # `self.conditional_layout` es un class_attribute y no puede variar por acción.
  def conditionally_skip_layout
    action_name == "full" ? "app_layout_preview" : super
  end

  def show
    load_listing(limit: PER_PAGE)
  end

  # The same listing, in the arrangement `height: :full` is built for: inside an
  # AppLayout that locks the viewport, so the split fills the screen and each
  # pane scrolls on its own instead of the page scrolling as a whole.
  def full
    load_listing(limit: FULL_PER_PAGE)
    render :full
  end

  private

  # A real screen picks one semantics and stays there. This page takes it from
  # a param so the reference can show both: `:single` is the bucket strip
  # (status, one value at a time) and `:multi` the independent toggles (genre,
  # several at once over `q[genre_in][]`).
  def load_listing(limit:)
    @filter_mode = params[:filter_mode] == "multi" ? :multi : :single
    @pagy, @movies = pagy(filtered.includes(:studio).order(:name), limit: limit)
    @selected = Movie.find_by(id: params[:selected])
  end

  def filtered
    @filter_mode == :multi ? by_genres : by_status
  end

  def by_status
    @status = params[:status].presence_in(Movie.statuses.keys)
    @counts = Movie.group(:status).count
    @status ? Movie.where(status: @status) : Movie.all
  end

  def by_genres
    @genres = Array(params.dig(:q, :genre_in)).select { |g| g.in?(Movie::GENRES) }
    @counts = Movie.group(:genre).count
    @genres.any? ? Movie.where(genre: @genres) : Movie.all
  end
end
