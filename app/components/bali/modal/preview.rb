# frozen_string_literal: true

module Bali
  module Modal
    class Preview < ApplicationViewComponentPreview
      # @param active toggle
      # @param size [Symbol] select [~, sm, md, lg, xl, full]
      def default(active: true, size: nil)
        render Modal::Component.new(active: active, size: size) do
          tag.div class: 'space-y-4' do
            safe_join([
                        tag.h3('Modal Title', class: 'text-lg font-bold'),
                        tag.p('This is the modal content. You can put anything here.')
                      ])
          end
        end
      end

      # @label With Slots
      # Use slots for structured modal content with header, body, and actions.
      # The header slot positions badges correctly and includes a close button.
      # @param active toggle
      # @param size [Symbol] select [~, sm, md, lg, xl, full]
      def with_slots(active: true, size: nil)
        render Modal::Component.new(active: active, size: size) do |modal|
          modal.with_header(title: 'Confirm Action', badge: 'Required', badge_color: :warning)
          modal.with_body do
            tag.p('Are you sure you want to proceed with this action? This cannot be undone.',
                  class: 'text-base-content/80')
          end
          modal.with_actions do
            safe_join([
              render(Bali::Button::Component.new(variant: :ghost, data: { action: 'modal#close' })) { 'Cancel' },
              render(Bali::Button::Component.new(variant: :primary)) { 'Confirm' }
            ])
          end
        end
      end

      # @label With Header Badge
      # Header slot supports badges that are right-aligned.
      # @param active toggle
      # @param badge_color [Symbol] select [primary, secondary, accent, info, success, warning, error]
      def with_header_badge(active: true, badge_color: :info)
        render Modal::Component.new(active: active, size: :md) do |modal|
          modal.with_header(title: 'User Details', badge: 'New', badge_color: badge_color)
          modal.with_body do
            tag.div class: 'space-y-2' do
              safe_join([
                tag.p('Name: John Doe'),
                tag.p('Email: john@example.com'),
                tag.p('Role: Administrator')
              ])
            end
          end
        end
      end

      # @label Form Modal
      # Example of a modal containing a form with action buttons.
      # @param active toggle
      def form_modal(active: true)
        render Modal::Component.new(active: active, size: :md) do |modal|
          modal.with_header(title: 'Create New Item')
          modal.with_body do
            tag.form class: 'space-y-4' do
              safe_join([
                tag.div(class: 'form-control') do
                  safe_join([
                    tag.label('Name', class: 'label', for: 'name'),
                    tag.input(type: 'text', id: 'name', class: 'input input-bordered w-full', placeholder: 'Enter name')
                  ])
                end,
                tag.div(class: 'form-control') do
                  safe_join([
                    tag.label('Description', class: 'label', for: 'description'),
                    tag.textarea(id: 'description', class: 'textarea textarea-bordered w-full', placeholder: 'Enter description', rows: 3)
                  ])
                end
              ])
            end
          end
          modal.with_actions do
            safe_join([
              render(Bali::Button::Component.new(variant: :ghost, data: { action: 'modal#close' })) { 'Cancel' },
              render(Bali::Button::Component.new(variant: :primary, data: { action: 'modal#submit' })) { 'Save' }
            ])
          end
        end
      end
    end
  end
end
