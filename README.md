# Bali ViewComponents

Collection of UI components using the ViewComponent library for easily building interfaces.

Uses StimulusJS for javascript functionality and SCSS along with the Bulma framework for styling.

## Usage

Render Bali components in an erb template:

```erb
  <%= render Bali::Link::Component.new(name: 'Link', href: '/') %>
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem "bali_view_components"
```

And this to the package.json

```bash
yarn add bali-view-components
```

To use a component add import the SCSS styles and JS if required.

## Contributing

To create a new component run:

```bash
rails g view_component hello_button name
```

We use [lookbook](https://github.com/allmarkedup/lookbook) to showcase the available components and develop new ones. To run the development server run:

```bash
cd spec/dummy && bin/dev
```

This script uses the [foreman](https://github.com/ddollar/foreman) gem to run the following:

- Rails server
- Process for JS compilation in watch mode
- Process for SCSS compilation in watch mode

Open your browser at: [http://localhost:3001/lookbook](http://localhost:3001/lookbook)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Javascript

Some javascript controllers emit events for communicating between controllers. To enable debugging this information run the following command on the javascript console. `baliDispatchDebugEnabled = true`

## Testing

### RSpec

To run ruby tests, run: `bundle exec rspec`

### Cypress

To run JavaScript tests:

- Run `rails server -p 3001`. The `http://localhost:3001/rails/view_components` has been configured as the baseUrl, and tests will fail if the server is not running
- Run `yarn run cy:run` to run tests in the terminal
- Or run `yarn run cy:open` to open the tests in the browser

# Lookbook

Lookbook gives ViewComponent-based projects a ready-to-go development UI for navigating, inspecting and interacting with component previews.

Project URL: https://github.com/allmarkedup/lookbook

To add a component, just create a `preview.rb` file within the component folder. Lookbook will automatically detect component previews and display them in the sidebar.

## Components' Status

Update this table when making progress on any of the Components or when adding new ones.

| Component Name          |     In Project     |      Preview       |        Docs        |       Tests        | Notes |
| ----------------------- | :----------------: | :----------------: | :----------------: | :----------------: | ----- |
| AddToCalendar           |        :x:         |        :x:         |        :x:         |        :x:         |       |
| Avatar                  | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Box                     |        :x:         |        :x:         |        :x:         |        :x:         |       |
| Breadcrumb              | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| BooleanIcon             | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Calendar                | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Carousel                | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Card                    | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Chart                   | :white_check_mark: | :white_check_mark: |    :wavy_dash:     | :white_check_mark: |       |
| Clipboard               | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Columns                 | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| DataTable               | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| DeleteLink              | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| DisplayValue            |        :x:         |        :x:         |        :x:         |        :x:         |       |
| Drawer                  | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Dropdown                | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Filters                 | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| GanttChart              | :white_check_mark: | :white_check_mark: | :white_check_mark: |        :x:         |       |
| Heatmap                 | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Hero                    | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Hovercard               | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Icon                    | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| ImageGrid               | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| InfoLevel               | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| LabelValue              | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Level                   | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Link                    | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| List                    | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Loader                  | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Modal                   | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| NavBar                  | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Notification            | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| PageHeader              | :white_check_mark: | :white_check_mark: |    :wavy_dash:     | :white_check_mark: |       |
| Progress                | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| PropertiesTable         | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark  |       |
| Rate                    | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Reveal                  | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| RichTextEditor          | :white_check_mark: | :white_check_mark: |        :x:         |        :x:         |       |
| SearchInput             | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| SideMenu                | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| SortableList            | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Stepper                 | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Table                   | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Tabs                    | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Timeago                 | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Timeline                | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| Tooltip                 | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| TreeView                | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |
| TurboNativeApp::SignOut | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |       |

## Stimulus JS Controllers

| Name                | Description                                                            | Tests |
| ------------------- | ---------------------------------------------------------------------- | ----- |
| AutoPlay            | It plays audio automatically when the page is loaded                   | :x:   |
| AutocompleteAddress | Autocompletes address using Google places API                          | :x:   |
| CheckboxToggle      | Toggles ON and OFF different elements based on the state of a checkbox | :x:   |
| Datepicker          | Uses the flatpickr library to render a Date Picker                     | :x:   |
| DynamicFields       | Renders input fields dynamically                                       | :x:   |
| ElementsOverlap     | Prevents a fixed elements overlaps a dynamic element                   | :x:   |
| FileInput           | Displays the selected filename in the correct place                    | :x:   |
| FocusOnConnect      | Scrolls an element into the visible area of the browser window         | :x:   |
| InputOnChange       | It notifies the server when there is some change in the input          | :x:   |
| Print               | Prints the current page                                                | :x:   |
| RadioToggle         | Shows different elements based on the value of a radio button          | :x:   |
| SlimSelect          | Uses Slim Select library to render a Select Input                      | :x:   |
| StepNumberInput     | Provides step number functionality to inputs                           | :x:   |
| SubmitButton        | Displays a loading button state when a form submission is started      | :x:   |
| SubmitOnChange      | Automatically submits the form when the form element changes value     | :x:   |
| TrixAttachments     | Allows to upload files with a certain size limit using the Trix editor | :x:   |

### Legends

| Icon               | Meaning          |
| ------------------ | ---------------- |
| :white_check_mark: | Is complete      |
| :wavy_dash:        | Incomplete       |
| :x:                | Missing entirely |
