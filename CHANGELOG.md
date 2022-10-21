# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.53.3] - 2022-10-21

### Added

- `wallet`, `wallet-alt`, `oxxo` icons.

## [0.53.2] - 2022-10-19

### Added

- Add option to specify a tooltip for a form label

## [0.53.1] - 2022-10-18

### Added

- Add `modal.fullwidth` class for full width modals
- Allow multiple CSS classes for the modal wrapper

## [0.53.0] - 2022-10-18

### Added

- Add `sparkles` icon

## [0.52.0] - 2022-10-17

### Changed

- Upgraded ruby and JS dependencies.

## [0.51.0] - 2022-10-15

### Added

- Create `ActionsDropdown::Component`

## [0.50.6] - 2022-10-14

### Added

- Add `chair`, `box-archive` and `file-export` icons
- Add option to add `custom-color` on tags

## [0.50.5] - 2022-10-14

### Added

- Add `url_field_group` form helper

## [0.50.4] - 2022-10-14

### Added

- Allow `SideMenu::Item` to render custom content

## [0.50.3] - 2022-10-13

### Added

- Add option to override when a `SideMenu::Item` should be active.

## [0.50.2] - 2022-10-12

### Added

- Add `align` option for `InfoLevel::Component`

## [0.50.1] - 2022-10-11

### Added

- `filters-alt` icon
- `closeOnClickOutside` as a value in `popup controller`. Default value is `true`.

## [0.50.0] - 2022-10-09

### Added

- Add `mode: range` for the `date_field` helper to allow for a range selection
- Create a preview for the `date_field`

## [0.49.0] - 2022-09-29

### Added

- Create `Hero::Component`

## [0.48.0] - 2022-09-29

### Added

- Create `LabelValue::Component` for displaying general values.

## [0.47.0] - 2022-09-27

### Updated

- `submit_actions` to display the cancel button in native apps when it is not being displayed inside a modal.

## [0.46.2] - 2022-09-27

### Fixed

- Display errors for `boolean_field_group` and fix styles when there are errors.

## [0.46.1] - 2022-09-27

### Fixed

- Add `is-danger` to datepicker input when there are errors.

## [0.46.0] - 2022-09-22

### Added

- `TurboNativeApp::SignOut` component.

## [0.45.1] - 2022-09-21

### Fixed

- Updated `GanttChart::Component` timeline headers calculation to fix current day flag and chart offset.

## [0.45.0] - 2022-09-15

### Updated

- Link component to add support for `native apps` when the `modal` attribute is set to `true`.
- Notification component to add `native-app` class. This class is useful for customizing the notification component when it appears in a native app.

## [0.44.0] - 2022-09-15

### Added

- Added a list footer to `GanttChart::Component`.

## [0.43.1] - 2022-09-13

### Fixed

- `dartsass-rails` requires replacing `image-url` with `url` to display icons/images.

## [0.43.0] - 2022-09-05

### Added

- Create `Progress::Component` for displaying a progress bar with percentage.

## [0.42.0] - 2022-08-30

### Added

- Create `List::Component` for displaying elements in a basic list

### Fixed

- Don't create a tippy instance when the contents are empty

## [0.41.2] - 2022-08-30

- Include third party CSS from the following libraries:
  - Trix
  - SlimSelect
  - Flatpickr

## [0.41.1] - 2022-08-29

- Allow `datepicker-controller` to enable/disabled weekends.

## [0.41.0] - 2022-08-27

- Migrate from `sassc-rails` to `dartsass-rails`
- Create new `PropertiesTable::Component`
- Add `Card::Header::Component` slot.
- Add `icon` option for `DeleteLink::Component` and add customize styles when it's inside a dropdown
- Add back button option for `PageHeader::Component`
- Update `more` icon

## [0.40.8] - 2022-08-27

- Add `month_field_group` method to generate fields with labels for date/year only inputs.

## [0.40.7] - 2022-08-24

- Added `badge-percent` icon.

## [0.40.6] - 2022-08-24

- Updated `GanttChart::Component` css to consider 4th level tasks.

## [0.40.5] - 2022-08-24

- Updated `Bali::Table::Component`. Fixes the `id` assignment for the table when `id` is defined inside `options`.

## [0.40.4] - 2022-08-24

- Updated `Bali::Table::Component`. Added an `id` to the `no records` row when the table is empty.

## [0.40.3] - 2022-08-24

- Add `infinity` icon.

## [0.40.2] - 2022-08-22

Fixes issue where using the back button resulted in the URL changing but the page not being updated. This was caused by manually manipulating the history object (history.pushState), because this interferes with how Turbo manages the restoration visits.

- removed `submitForm` function. Recommended approach is to call `form.requestSubmit()`

## [0.40.1] - 2022-08-18

Add `GanttChart::TaskActions::Component` displaying a menu with options for each task:

- Opening details
- Indent
- Outdent
- Delete

Refactor `HoverCard::Component` to use tippy to simplify and handle more options.

## [0.40.0] - 2022-08-18

Create `GanttChart::Component` for a full fledged Gantt Chart with the following functionality:

- Display a sortable and nestable list of tasks
- Fold/Unfold the nested lists
- Actions for changing the timescale between Day, Week and Month
- Button for focusing today's date and a today marker
- Draggable and Resizable tasks
- Visualize dependencies between tasks
- Display of milestones
- Resizable width of the task list
- Visualize weekends

## [0.39.1] - 2022-08-16

- Fix `Navbar` transparency.

## [0.39.0] - 2022-08-15

- Added `Clipboard` component. Copy text to clipboard.
- Added `copy`, `link-alt` icons.

## [0.38.1] - 2022-08-15

- Clean up event listeners from all StimulusJS controllers
- Override `SlimSelect#destroy` function to check for the presence of slim elements before removing them.

## [0.38.0] - 2022-08-14

- Convert `HelpTip` to a more general `Tooltip`. To create a HelpTip out of a Tooltip simply set a `<span>?</span>` as a trigger and add the class `help-tip` to the root component.

## [0.37.1] - 2022-08-12

- Update `ModalController` to check for targets (Wrapper and Background) existence before attempting action.

## [0.37.0] - 2022-08-5

- `radio-buttons-group-controller` was created.
- Update `ModalController` to look for `data-turbo` attribute in the form if it was not present in the `event.target`.

## [0.36.0] - 2022-08-4

- Update `radio-toggle-controller` to accept multiple values in current value.

## [0.35.1] - 2022-08-3

- Remove `stroke` attribute from `rect` and add `stroke` and `fill` in `svg` icons.

## [0.35.0] - 2022-08-3

- Add `under-modal` class to hide the hover-card when is necessary.

## [0.34.0] - 2022-08-3

- Add `open_on_click` property to `HoverCard::Component` to open the content on click.

## [0.33.0] - 2022-07-29

- Add `show_border` to `Reveal::Component` to show or hide the `border-bottom` just below the trigger.

## [0.32.2] - 2022-07-28

- Add `new` to CRUD actions to display an active tab when current_path is matched.

## [0.32.1] - 2022-07-28

- Remove `stimulus-chartjs` dependency.

## [0.32.0] - 2022-07-25

- Add `Timeago::Component`.

## [0.31.0] - 2022-07-25

- Add `Heatmap::Component`.

## [0.30.6] - 2022-07-18

- Add `crud` match type to `SideMenu::Item`. So it only considers items as active when current_path is one of the CRUD actions (index, show, edit.)

## [0.30.5] - 2022-07-18

- Add `starts_with` match type to `SideMenu::Item`. So it only considers items as active when current_path starts with the item's HREF

## [0.30.4] - 2022-07-18

- Only consider exact URL matches for displaying a `SideMenu::Item` as active. This fixes a problem where 2 items had a similar URL and both were considered active.

## [0.30.3] - 2022-07-14

- `step-number-input` controller was updated to be able to set a custom step.

## [0.30.2] - 2022-07-14

- Updated `PageHeader::Component` CSS to prevent overflow.

## [0.30.1] - 2022-07-12

- Updated `PageHeader::Component`, title and subtitle slots now receive an optional tag param to specify the size of the heading. New default title size is `h3` and subtitle is `h5`.

## [0.30.0] - 2022-07-11

- Create `Tags::Component` to display tags groups.
- Create `Tag::Component` to display individual tags.

## [0.29.0] - 2022-07-08

- Create `Rate::Component` to give feedback on something.

## [0.28.1] - 2022-07-08

- Allowed `InfoLevel::Component` to receive a block on its heading and title.

## [0.28.0] - 2022-07-08

- Create `Timeline::Component` to display contents in a vertical timeline

## [0.27.1] - 2022-07-07

- Update README with component updates
- Add `ImageGrid::Component` tests
- Add `Column::Component` previews
- Standardize on expect(page) syntax instead of using subject + is_expected

## [0.27.0] - 2022-07-07

- Added the `TrixAttachmentsController` for handling attachments in the `Trix` editor.

## [0.26.1] - 2022-07-07

- Fixed an issue when using icons in the content of `Reveal::Component`

## [0.26.0] - 2022-07-07

- Create `Reveal::Component` to display hidden content that can be revealed.

## [0.25.2] - 2022-07-06

- Upgrade dependencies.

## [0.25.1] - 2022-07-06

- Export `domHelpers`.

## [0.25.0] - 2022-07-05

- Add `Avatar::Component`. With this component we'll be able to see a preview of the image we want as an avatar.

## [0.24.4] - 2022-07-05

- Let `DeleteLink::Component` receive form classes for the `buttton_to` tag.

## [0.24.3] - 2022-07-05

- Add `type="button"` to Carousel controls (`arrows`, `bullets`).

## [0.24.2] - 2022-07-05

- Wrap card image slot in `slot` instead of `div`.

## [0.24.1] - 2022-07-05

- Set SideMenu list with optional title

## [0.24.0] - 2022-07-05

- `arrows` and `bullets` slots were added to `Carousel` component.

## [0.23.4] - 2022-07-05

- Fix SideMenu parent item when sub item is selected

## [0.23.3] - 2022-07-04

- Fix SideMenu sub items show only when active

## [0.23.2] - 2022-07-04

- Set `Delete` as default name for `DeleteLink::Component`

## [0.23.1] - 2022-07-04

- Add `Tabs::Trigger::Component`. In addition, a tab will cause the entire page to be reloaded when `href` is present.

## [0.23.0] - 2022-07-01

- Add `toInt` and `toFloat` JS formatters

## [0.22.0] - 2022-07-01

- Create `Carousel::Component`.

## [0.21.0] - 2022-07-01

- Create `SortableList::Component` to sort items in a list.

## [0.20.1] - 2022-07-01

- Display `SideMenu::Component` child items when item is active.

## [0.20.0] - 2022-07-01

- Create `Breadcrumb::Component` to improve the navigation experience

## [0.19.1] - 2022-07-01

- Custom notifications have been added for `no results/no records` in the table component.

## [0.19.0] - 2022-07-01

- Create `Stepper::Component` to display steps completed in a process

## [0.18.0] - 2022-06-30

- Added a `FormHelper` to add the `submit-button-controller` to the `form_for` method.

## [0.17.1] - 2022-06-30

- Update `hyphenize_keys` to return a hash in which the keys are symbols instead of strings.

## [0.17.0] - 2022-06-30

- Create `BooleanIcon::Component` and update Component Generator templates.

## [0.16.0] - 2022-06-30

- Added non-component stylesheets (`box`, `code`, `container`, `flatpickr_customizations`, `forms`, `general`, `panel`, `slim_select_customizations`, `switch`, `typography`, `variables`). In addition missing Hover Card styles (Frontend helpers) have been added to the Hover card.

## [0.15.3] - 2022-06-30

-Reorganize specs to have all tests within a bali/ folder.

## [0.15.2] - 2022-06-30

- Improve `FormBuilder` testing.

## [0.15.1] - 2022-06-29

- Pass the `options` parameter to the `SideMenu::Item::Component`.

## [0.15.0] - 2022-06-28

- Added `FormBuilder` and `FieldGroupWrapperComponent`.

## [0.14.0] - 2022-06-28

- Added `SideMenu::Component`.

## [0.13.0] - 2022-06-28

- Added Stimulus JS Controllers
  [`auto-play-audio`, `autocomplete-address`, `checkbox-toggle`, `elements-overlap`,
  `focus-on-connect`, `input-on-change`, `print`, `radio-toggle`, `submit-button`].

## [0.12.0] - 2022-06-24

- Added utils methods.

## [0.11.0] - 2022-06-23

- Added `wide` css class to `Dropdown::Component`.

## [0.10.0] - 2022-06-23

- Added conditional layout concern.

## [0.9.0] - 2022-06-22

- Added Time Value class and its corresponding tests.

## [0.8.1] - 2022-06-22

- Remove double validation in `Link::Component`.

## [0.8.0] - 2022-06-21

- Fix style in `Link::Component`.

## [0.7.0] - 2022-06-21

- Added FilterForm class and its corresponding tests.

## [0.6.0] - 2022-06-21

- Added Notification Component.

## [0.5.0] - 2022-06-17

- Completed `Loader` component.

## [0.3.0] - 2022-06-16

- Completed `Tabs` component. Added loading tab content on demand.

## [0.2.0] - 2022-06-15

- Completed `Link` and `Calendar` components.

## [0.1.0] - 2022-06-10

- `Navbar` component was added.
