# frozen_string_literal: true

# The row, written once, so the grouped and ungrouped branches of the view can
# show the thing that matters about grouping: **the row call does not change.**
# `slot` is the list in one branch and a group in the other, and both answer
# `with_item` with the same keywords.
module SplitViewsHelper
  def render_split_view_row(slot, movie)
    slot.with_item(
      id: movie.id,
      # Everything the current listing is, plus the selection — so a deep link
      # lands on the same listing and not on a default one. `page` is the
      # exception: a row is not on a page, it is in a list.
      href: split_view_path(request.query_parameters.except("page").merge(selected: movie.id)),
      title: movie.name,
      subtitle: movie.studio&.name,
      meta: movie.production_ends_on && l(movie.production_ends_on, format: :short),
      meta_color: (:error if movie.production_ends_on&.past?)
    ) do |row|
      row.with_tag(text: movie.genre, color: :info)
      row.with_tag(text: movie.status.humanize, color: movie.status_color)
    end
  end
end
