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

| Component Name |     In Project     |      Preview       |       Tests        |
| -------------- | :----------------: | :----------------: | :----------------: |
| Card           | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| Chart          | :white_check_mark: |        :x:         |        :x:         |
| Columns        | :white_check_mark: |        :x:         |        :x:         |
| Dropdown       | :white_check_mark: |        :x:         |        :x:         |
| HelpTip        | :white_check_mark: |        :x:         |        :x:         |
| ImageGrid      | :white_check_mark: |        :x:         |        :x:         |
| InfoLevel      | :white_check_mark: |        :x:         |        :x:         |
| Level          | :white_check_mark: |        :x:         |        :x:         |
| Modal          | :white_check_mark: |        :x:         |        :x:         |
| PageHeader     | :white_check_mark: |        :x:         |        :x:         |
| Table          | :white_check_mark: |        :x:         |        :x:         |
| Tabs           | :white_check_mark: |        :x:         |        :x:         |
| TreeView       | :white_check_mark: |        :x:         |        :x:         |
| Chart          | :white_check_mark: |        :x:         |        :x:         |

### Legends

| Icon               | Meaning          |
| ------------------ | ---------------- |
| :white_check_mark: | Is complete      |
| :wavy_dash:        | Incomplete       |
| :x:                | Missing entirely |
