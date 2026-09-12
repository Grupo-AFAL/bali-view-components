// UI strings of the Gantt island (#705, decision D12). The island receives an
// `i18n` prop — a FLAT object served by Rails from `bali_view.gantt.island.*`
// (see Bali::Gantt::Translations) — and falls back to these English defaults
// key by key when the prop is empty or partial. Same pattern as the
// BlockEditor's `translations` value: texts are server-rendered Stimulus
// values, never hardcoded in the bundle.
//
// Interpolation uses Rails' `%{name}` placeholders so the same string works
// from both sides.
export const DEFAULT_I18N = {
  add_group: 'Group',
  add_group_hint: 'Add group',
  add_item: 'Item',
  add_item_hint: 'New item',
  search_placeholder: 'Search…',
  filter: 'Filter',
  filter_by_status: 'Filter by status',
  all: 'All',
  columns: 'Columns',
  show_columns: 'Show columns',
  col_name: 'Name',
  col_assignee_short: 'Owner',
  col_assignee: 'Assignee',
  col_dates: 'Dates',
  col_days: 'Days',
  col_status: 'Status',
  col_progress: 'Progress',
  critical: 'Critical',
  critical_hint: 'Highlight critical path',
  deps: 'Deps',
  deps_hint: 'Show dependencies',
  color: 'Color',
  color_by: 'Color by',
  color_status: 'Status',
  color_assignee: 'Owner',
  color_group: 'Group',
  color_priority: 'Priority',
  zoom_label: 'Zoom',
  zoom_day: 'Day',
  zoom_week: 'Week',
  zoom_month: 'Month',
  today: 'Today',
  go_to_today: 'Go to today',
  zoom_in: 'Zoom in',
  zoom_out: 'Zoom out',
  fit: 'Fit to window',
  fullscreen: 'Full screen',
  expand: 'Expand',
  collapse: 'Collapse',
  selection_none: 'No selection',
  selected: '%{count} selected',
  items_count: '%{count} items',
  undated_count: '%{count} with no dates',
  range_days: '%{count} days',
  critical_count: 'critical: %{count}',
  progress_label: '%{percent}% complete',
  resize_start: 'Resize (start)',
  resize_duration: 'Resize (duration)',
  drag_dependency: 'Drag to another bar to create a dependency',
  minimap_hint: 'Minimap — click or drag to navigate',
  splitter_hint: 'Drag to resize the table',
  schedule_refreshed: 'The schedule was refreshed (an item had changed).',
  change_failed: 'The change could not be applied',
  load_error: 'The timeline failed to load.'
}

// t(key, vars) over the merged table. Unknown keys return the key itself so a
// typo shows up on screen instead of vanishing.
export function translator (overrides) {
  const table = { ...DEFAULT_I18N, ...(overrides || {}) }
  return (key, vars) => {
    let str = String(table[key] ?? key)
    if (vars) {
      for (const [name, value] of Object.entries(vars)) {
        str = str.replaceAll(`%{${name}}`, String(value))
      }
    }
    return str
  }
}
