# Bali

Short description and motivation.

## Usage

How to use my plugin.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "bali"
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install bali
```

## Contributing

Contribution directions go here.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Testing

### RSpec

To run ruby tests, run: `bundle exec rspec`

### Cypress

To run JavaScript tests:

- Run `rails server`. The `http://localhost:3000/rails/view_components` has been configured as the baseUrl, and tests will fail if the server is not running
- Run `yarn run cy:run` to run tests in the terminal
- Or run `yarn run cy:open` to open the tests in the browser

# Lookbook

Lookbook gives ViewComponent-based projects a ready-to-go development UI for navigating, inspecting and interacting with component previews.

Project URL: https://github.com/allmarkedup/lookbook

To add a component, just create a `preview.rb` file within the component folder. Lookbook will automatically detect component previews and display them in the sidebar.

## Components' Status

Update this table when making progress on any of the Components or when adding new ones.

| Component Name    |     In Project     |      Preview       |        Docs        |       Tests        | Notes                                          |
| ----------------- | :----------------: | :----------------: | :----------------: | :----------------: | ---------------------------------------------- |
| AddToCalendar     |        :x:         |        :x:         |        :x:         |        :x:         |                                                |
| Box               |        :x:         |        :x:         |        :x:         |        :x:         |                                                |
| Breadcrumb        |        :x:         |        :x:         |        :x:         |        :x:         | Create from scratch                            |
| BurgerButton      |        :x:         |        :x:         |        :x:         |        :x:         |                                                |
| Calendar          | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |                                                |
| Carousel          |        :x:         | :white_check_mark: |        :x:         | :white_check_mark: | Two versions in Enjoy and GA, need to merge    |
| Card              | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |                                                |
| Chart             | :white_check_mark: | :white_check_mark: |    :wavy_dash:     | :white_check_mark: |                                                |
| Collapse (Reveal) |        :x:         |        :x:         |        :x:         |        :x:         | Rename from Reveal to Collapse                 |
| Columns           | :white_check_mark: | :white_check_mark: |        :x:         | :white_check_mark: |                                                |
| DataTable         | :white_check_mark: | :white_check_mark: |        :x:         | :white_check_mark: |                                                |
| DeleteLink        | :white_check_mark: | :white_check_mark: |        :x:         | :white_check_mark: |                                                |
| DisplayValue      |        :x:         |        :x:         |        :x:         |        :x:         |                                                |
| Drawer            | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |                                                |
| Dropdown          | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |                                                |
| Filters           | :white_check_mark: | :white_check_mark: |        :x:         | :white_check_mark: |                                                |
| GanttChart        |        :x:         |        :x:         |        :x:         |        :x:         |                                                |
| Heatmap           |        :x:         |        :x:         |        :x:         |        :x:         |                                                |
| HelpTip           | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |                                                |
| Hero              |        :x:         |        :x:         |        :x:         |        :x:         |                                                |
| Hovercard         | :white_check_mark: | :white_check_mark: |        :x:         | :white_check_mark: |                                                |
| Icon              | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |                                                |
| ImageGrid         | :white_check_mark: | :white_check_mark: | :white_check_mark: |        :x:         |                                                |
| InfoLevel         | :white_check_mark: | :white_check_mark: |        :x:         | :white_check_mark: |                                                |
| Level             | :white_check_mark: | :white_check_mark: |        :x:         | :white_check_mark: |                                                |
| Link              | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |                                                |
| Loader            |        :x:         |        :x:         |        :x:         |        :x:         |                                                |
| Modal             | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |                                                |
| NavBar            | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |                                                |
| Notification      |        :x:         |        :x:         |        :x:         |        :x:         |                                                |
| PageHeader        | :white_check_mark: | :white_check_mark: |    :wavy_dash:     | :white_check_mark: |                                                |
| ProfilePicture    |        :x:         |        :x:         |        :x:         |        :x:         |                                                |
| Rate (Rating)     |        :x:         |        :x:         |        :x:         |        :x:         | Rename from Rating to Rate                     |
| SearchInput       | :white_check_mark: | :white_check_mark: |        :x:         | :white_check_mark: |                                                |
| SideMenu          |        :x:         |        :x:         |        :x:         |        :x:         |                                                |
| SortableList      |        :x:         |        :x:         |        :x:         |        :x:         |                                                |
| Steps (Progress)  |        :x:         |        :x:         |        :x:         |        :x:         | Rename from Progress to Steps                  |
| Table             | :white_check_mark: |    :wavy_dash:     |        :x:         | :white_check_mark: |                                                |
| Tabs              | :white_check_mark: | :white_check_mark: |        :x:         |        :x:         |                                                |
| Timeline          |        :x:         |        :x:         |        :x:         |        :x:         | Create from scratch, HTML already exists on GA |
| TreeView          | :white_check_mark: | :white_check_mark: |        :x:         | :white_check_mark: |                                                |

### Legends

| Icon               | Meaning          |
| ------------------ | ---------------- |
| :white_check_mark: | Is complete      |
| :wavy_dash:        | Incomplete       |
| :x:                | Missing entirely |
