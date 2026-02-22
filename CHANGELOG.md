# Changelog

## [Unreleased]

### Added

- Optional search input for `SimpleFilters::Component` with `search:` parameter
- `FilterForm#simple_search_config` convenience method for SimpleFilters integration
- Default `mb-6` margin to `PageHeader::Component`

### Fixed

- `Tabs::Trigger::Component` now respects explicit `active:` parameter when `href` is present
- `PathHelper#active_path?` strips query params from both path arguments symmetrically
