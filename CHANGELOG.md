# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.1] - 2024-01-30

### Fixed
- Redirection issues when attempting to open a restricted modal.

## [1.3.0] - 2024-10-18

### Changed
- Upgrade to `rails` to `7.2`
- Update `gems` and `importmap`

## [1.2.5] - 2024-09-17

### Changed
- Added `submit-actions` class name to `submit_actions` fields helper.

## [1.2.4] - 2024-07-25

### Changed
- Updated `rails` to version `7.1.4`

## [1.2.3] - 2024-07-25

### Changed
- Updated gems and npm packages

## [1.2.2] - 2024-06-06

### Fixed
- Cannot read properties of undefined (reading 'destroy') in `stimulus` controllers.
- Missing target element "menu" for "navbar" controller

## [1.2.1] - 2024-05-20

### Fixed
- Incorrect `for` attribute value in radio buttons of `radio_buttons_field_group` when  value is a datetime

## [1.2.0] - 2024-05-06

### Changed

- import `GoogleMapsLoader` dynamically
- import `tippy` dynamically
- import `Sortable` dynamically
- import `Chart` dynamically
- import `MarkerClusterer` dynamically
- import `createPopper` dynamically

## [1.1.1] - 2024-05-09

### Fixed

- imports with relative paths were failing in `js` files.

## [1.1.0] - 2024-03-08

### Added

- Button to clear polygons in coordinates polygon field
- Button to clear holes in coordinates polygon field

## [1.0.0] - 2024-04-17

### Changed

- Migrated from `jsbundling-rails` to `importmaps-rails`

## [0.76.0] - 2024-04-17

### Added

- Updated `gems` and `npm` packages

## [0.75.0] - 2024-02-28

### Added

- `Bali::Commands::XlsxExport` class. This class allows us to use DSL in xlsx export.

## [0.74.1] - 2024-02-19

### Fixed

- Fix InputOnChangeController#change. Updated to use the new Slim Select 2.0 API.

## [0.74.0] - 2024-02-15

### Changed

- Allow `DrawingMapsController` to draw and export multiple polygons classified into shells and holes. As a result, the value from `coordinates_field` and `coordinated_field_group` has changed from `[{ lat: , lng:}]` to `{ shells: [{ lat: , lng:}], holes: [{ lat: , lng:}] }`. This format `[{ lat: , lng:}]` is still working to initilize the polygons within the map, but changes in the map will be store using the new format.

## [0.73.0] - 2024-01-31

### Fixed

- Slim select does not render

## [0.73.0] - 2024-01-30

### Changed

- Updated gems and npm packages

## [0.72.0] - 2024-01-26

### Added

- `Bali::Commands::CsvExport` class. This class allows us to use DSL in csv export.

## [0.71.1] - 2024-01-22

### Fixed

- Use `as` attribute of `form_for` in the `id` of the radio buttons when using `radio_buttons_group`

## [0.71.0] - 2023-11-28

### Added

- `Bali::BulkActions::Component` component. This component enables you to double-click on multiple DOM elements, selecting them, and subsequently applying an action.

## [0.70.0] - 2023-10-06

### Added

- `Cards` to `LocationsMap::Component`. These cards help to display detailed information for each marker. When a marker is clicked on, all cards matching the latitude and longitude of the marker will have the `is-selected` class added to them.

## [0.69.0] - 2023-09-19

### Changed

- Unify the data structure of the `Chart` component and `Chart.js`.

## [0.68.1] - 2023-09-19

### Fixed

- `name` attribute of the html `label` element of `switch_field_group`.

## [0.68.0] - 2023-09-19

### Added

- Add `display_percent` option on `Chart::Component` for automatically calculating and displaying percentages on the tooltip

## [0.67.3] - 2023-08-23

### Added

- `youtube` icon
- `title` to `mexican flag` icon
- `title` to `usa flag` icon
- `title` to `shopping cart` icon

### Changed

- color of the `facebook` and `instagram` icons to `currentColor`

### Changed

- `facebook` and `instagram` icons to fill with the current color.

## [0.67.2] - 2023-08-23

### Added

- `.is-margin-auto` CSS style
- `.is-circle` CSS style
- `.is-unclosable` CSS stlye to notification component. This css style hides the button to close the notification
- `icon_tag` helper method
- `Bali::TenancyTestsHelper`
- `Bali::TestsHelper`
- `Bali::Concerns::Mailers::RecipientsSanitizer`. This concern includes `send_mail` method, which removes inactive emails before sending mail.
- `Bali::Concerns::Mailers::UtmParams`
- `Bali::FlashNotifications::Component`

## [0.67.1] - 2023-08-15

### Changed

- Add CSS classes for different widths for select fields

## [0.67.0] - 2023-08-11

### Added

- Add ability to add custom filters on the Filters::Component
- Create `Bali::Types::DateRangeValue` to support :date_range type in `attribute` method

## [0.66.3] - 2023-08-08

### Added

- Custom class in the `currency_field_group` label when it renders a tooltip.

### Fixed

- Issue when an input field has an add-on and error

## [0.66.2] - 2023-07-18

### Added

- `Bali::Concerns::SoftDelete`
- `Bali::Concerns::Controllers::DeviceConcern`
- `GeocodeAdddressController` (javascript)
- `ios_naitve_app_user_agent` and `android_native_app_user_agent` as `Bali` configuration

## [0.66.1] - 2023-07-12

### Fixed

- Skip rendering for `ActionsDropdown::Component` when no content is present

## [0.66.0] - 2023-06-16

### Added

- Add `allow_input` to datepicker to be able to manually enter a date

## [0.65.1] - 2023-06-13

### Changed

- Relax ruby dependency to allow greater than `3.2`
- Update `library_version.thor` script to autodetect current version and increment it.
- Update Library authors

## [0.65.0] - 2023-06-07

### Changed

- Allow to add attributs to the FilterForm where only 1 value can be selected

### Fixed

- `TableController` check for elements presence before updating.

## [0.64.0] - 2023-06-05

### Added

- Add ability to add bulk actions to a `Table::Component`

## [0.63.0] - 2023-06-01

### Added

- Allow to persist the `FilterForm` filters across requests

## [0.62.0] - 2023-05-25

### Added

- Allow `slim_select_field` to autocomplete options from the server.

## [0.61.8] - 2023-05-23

### Changed

- Allow to add custom data attributes to `add/subtract` buttons in the step number field.

## [0.61.7] - 2023-05-14

### Fixed

- Pass the correct `route_path` argument instead of `route_name` to `Calendar::Header`

## [0.61.6] - 2023-04-18

### Changed

- Allows adding `custom icons` from the host application to the `Bali::Icon::Component`.

## [0.61.5] - 2023-03-31

### Added

- `Bali::Concerns::DateRangeAttribute` concern. This concern allows to define date range attributes, for example, `date_range_attribute :date_range, default: Time.zone.now.all_day`
- `max_date` option to `date_field_group` and `date_field`. you to set a maximum date that can be selected

## [0.61.4] - 2023-03-30

### Changed

- Renamed `route_name` to `route_path` in `Calendar` component. `route_path` expects a string, for example, `/lookbook`.

## [0.61.3] - 2023-03-26

### Fixed

- Fix `ransack` deprecation warning by avoiding passing a nil value to the `sort_link` method.

## [0.61.2] - 2023-03-14

### Added

- Add prefix and suffix to axis labels (`Chart` component)
- Prevent the tooltip title from being truncated (`Chart` component)
- Add prefix and suffix to tooltip label (`Chart` component)

## [0.61.1] - 2023-03-14

### Fixed

- Allow `TimeValue` to receive date string without seconds

## [0.61.0] - 2023-03-13

### Added

- Add `Message::Component`

### Changed

- Upgrade Gems

## [0.60.0] - 2023-03-13

### Changed

- `TimeValue`now returns a `Time` object when retrieved from DB to be able to format it.
- `time_field_group` is updated to handle a `Time` value instead of a `String`

## [0.59.2] - 2023-03-10

### Added

- Added sticky headers for table component.

## [0.59.1] - 2023-03-11

### Fixed

- Correctly scope the previous `ActionsDropddown::Component` css change.

## [0.59.0] - 2023-03-11

### Added

- Added a `readonly` option for the `Rate::Component` for display only purposes.

### Changed

- Add bottom-margin to `ActionsDropddown::Component` when placed inside a `.buttons` element to align with other buttons.

## [0.58.2] - 2023-02-20

### Changed

- Allow to override the `submit-on-change` `method` and `action` values throught the StimulusJS controller

## [0.58.1] - 2023-02-15

### Changed

- Ability to add multiple actions in a `List::Item::Component`
- Ability to add content in the middle of a `List::Item`

## [0.58.0] - 2023-02-11

### Changed

- Add ability to manage multiple files in a File Input

## [0.57.1] - 2023-02-02

### Added

- `@tiptap/pm` to `package.json` as `dependency`

### Fixed

- `Module not found` error when compiling assets in host application.

## [0.57.0] - 2023-01-31

### Fixed

- Added `Bali::Concerns::NumericAttributesWithCommas`. This concern complements the `percentage_field_group` and `currency_field_group` methods by removing the `commas` before saving the value to the DB.

## [0.56.3] - 2023-01-29

### Fixed

- Perform `Filters::Component` request with a `turbo_stream` format

## [0.56.2] - 2022-12-22

### Added

- Add `question-circle` icon

## [0.56.1] - 2022-12-20

### Added

- Add ability to specify a `submitter` on the `SubmitOnChange` controller in order to specify a different formaction and formmethod

## [0.56.0] - 2022-12-16

### Added

- Dispatch the `modal:success` event when the form is successfully submitted.

## [0.52.7] - 2022-12-06

### Added

- Allow to specity vertical alignment as a param for `Level::Component`

## [0.52.6] - 2022-12-02

### Changed

- Align file field ergonomics with other form inputs

## [0.52.5] - 2022-12-02

### Added

- Display all files selected in `file-input`

## [0.52.4] - 2022-12-02

### Fixed

- Fix `radio_field_group` display when it has an error.

## [0.52.3] - 2022-11-30

### Added

- Add `disabled` support for `Link::Component`

## [0.55.2] - 2022-11-30

### Added

- Add ability to display an icon in the trigger of the reveal component.

## [0.55.1] - 2022-11-16

### Added

- Add ability to hide `Table::Component` th

## [0.55.0] - 2022-11-16

### Added

- `Page Hyperlinks` to `Rich Text Editor`.

## [0.54.3] - 2022-11-15

### Added

- Add option to pass a container class to the `Navbar::Component`

## [0.54.2] - 2022-11-14

### Added

- `additional query params` to filters component. This helps to add query parameters not related to the form.

## [0.54.1] - 2022-11-11

### Updated

- Add a parameter to the `datepicker controller` to decide whether or not the alt input should be rendered.

## [0.54.0] - 2022-11-08

### Added

- Create `RichTextEditor::Component`

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
