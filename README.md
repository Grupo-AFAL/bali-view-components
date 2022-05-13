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

# Storybook

There are several pieces to involved in configuring view_components and generating the
necesarry files to display the view_components in Storybook.

## View Component Storybook

**Github repository:** https://github.com/jonspalmer/view_component_storybook

The ViewComponent::Storybook gem provides Ruby api for writing stories describing View Components
and allowing them to be previewed and tested in Storybook via its Server support.

### Rebuild Storybook

```sh
rake storybook:rebuild
```

Go to: http://localhost:3000/_storybook/index.html

> **_NOTE:_** If your new component does not show up on the storybook component list, a posible solution might be to delete your browser cookies or use incognito mode.

The rake command does 2 things:

#### Generate JSON stories from Ruby files

##### `rake view_component_storybook:write_stories_json`

View component storybook provides us with a way to configure storybook stories in ruby, but Storybook expects JSON files for that configuration. In order for Storybook to work we need a step where the ruby files are converted to the JSON configuration files Storybook expects.

#### Build Storybook

##### `build-storybook -o public/_storybook`

Storybook needs to compile the JSON files in order to generate a static site where the actual Storybook lives.
