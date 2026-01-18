# frozen_string_literal: true

module Bali
  module TreeView
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # A file/folder navigation tree with expandable sections.
      # Click the chevron icons to expand/collapse sections.
      def default
        render(Bali::TreeView::Component.new(current_path: '/docs/guides/getting-started')) do |c|
          c.with_item(name: 'Home', path: '/')

          c.with_item(name: 'Documentation', path: '/docs') do |docs|
            docs.with_item(name: 'Introduction', path: '/docs/introduction')
            docs.with_item(name: 'Installation', path: '/docs/installation')
            docs.with_item(name: 'Configuration', path: '/docs/configuration')
          end

          c.with_item(name: 'Guides', path: '/docs/guides') do |guides|
            guides.with_item(name: 'Getting Started', path: '/docs/guides/getting-started')
            guides.with_item(name: 'Basic Usage', path: '/docs/guides/basic-usage')
            guides.with_item(name: 'Advanced Topics', path: '/docs/guides/advanced')
            guides.with_item(name: 'Best Practices', path: '/docs/guides/best-practices')
            guides.with_item(name: 'Troubleshooting', path: '/docs/guides/troubleshooting')
          end

          c.with_item(name: 'API Reference', path: '/api') do |api|
            api.with_item(name: 'Authentication', path: '/api/auth')
            api.with_item(name: 'Users', path: '/api/users')
            api.with_item(name: 'Products', path: '/api/products')
            api.with_item(name: 'Orders', path: '/api/orders')
          end

          c.with_item(name: 'Components', path: '/components') do |components|
            components.with_item(name: 'Buttons', path: '/components/buttons')
            components.with_item(name: 'Forms', path: '/components/forms')
            components.with_item(name: 'Tables', path: '/components/tables')
            components.with_item(name: 'Modals', path: '/components/modals')
            components.with_item(name: 'Navigation', path: '/components/navigation')
          end

          c.with_item(name: 'Examples', path: '/examples') do |examples|
            examples.with_item(name: 'Dashboard', path: '/examples/dashboard')
            examples.with_item(name: 'E-commerce', path: '/examples/ecommerce')
            examples.with_item(name: 'Blog', path: '/examples/blog')
          end

          c.with_item(name: 'Changelog', path: '/changelog')
          c.with_item(name: 'Support', path: '/support')
        end
      end

      # @label All Collapsed
      # Tree with no active item - all sections collapsed by default.
      def all_collapsed
        render(Bali::TreeView::Component.new(current_path: '/other')) do |c|
          c.with_item(name: 'Project Files', path: '/files') do |files|
            files.with_item(name: 'src', path: '/files/src')
            files.with_item(name: 'tests', path: '/files/tests')
            files.with_item(name: 'docs', path: '/files/docs')
          end

          c.with_item(name: 'Configuration', path: '/config') do |config|
            config.with_item(name: 'database.yml', path: '/config/database')
            config.with_item(name: 'routes.rb', path: '/config/routes')
            config.with_item(name: 'application.rb', path: '/config/application')
          end

          c.with_item(name: 'Assets', path: '/assets') do |assets|
            assets.with_item(name: 'images', path: '/assets/images')
            assets.with_item(name: 'stylesheets', path: '/assets/stylesheets')
            assets.with_item(name: 'javascripts', path: '/assets/javascripts')
          end
        end
      end

      # @label Multiple Expanded
      # Tree with multiple sections expanded (active items in different branches).
      def multiple_expanded
        render(Bali::TreeView::Component.new(current_path: '/api/users')) do |c|
          c.with_item(name: 'Frontend', path: '/frontend') do |frontend|
            frontend.with_item(name: 'React Components', path: '/frontend/react')
            frontend.with_item(name: 'Vue Components', path: '/frontend/vue')
            frontend.with_item(name: 'Styles', path: '/frontend/styles')
          end

          c.with_item(name: 'Backend', path: '/backend') do |backend|
            backend.with_item(name: 'Controllers', path: '/backend/controllers')
            backend.with_item(name: 'Models', path: '/backend/models')
            backend.with_item(name: 'Services', path: '/backend/services')
          end

          c.with_item(name: 'API', path: '/api') do |api|
            api.with_item(name: 'Users', path: '/api/users')
            api.with_item(name: 'Posts', path: '/api/posts')
            api.with_item(name: 'Comments', path: '/api/comments')
          end

          c.with_item(name: 'Database', path: '/database') do |db|
            db.with_item(name: 'Migrations', path: '/database/migrations')
            db.with_item(name: 'Seeds', path: '/database/seeds')
          end
        end
      end
    end
  end
end
