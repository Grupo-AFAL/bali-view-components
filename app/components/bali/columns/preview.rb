# frozen_string_literal: true

module Bali
  module Columns
    class Preview < ApplicationViewComponentPreview
      # Columns
      # -------
      # To help layout items in a page.
      def default
        render Columns::Component.new do |c|
          c.column(class: 'is-half') do
            c.tag.div(class: 'box') do
              tag.p 'First Column'
            end
          end

          c.column(class: 'is-half') do
            c.tag.div(class: 'box') do
              tag.p 'Second Column'
            end
          end
        end
      end

      # Narrow column
      def narrow
        render Columns::Component.new do |c|
          c.column(class: 'is-narrow') do
            c.tag.div(class: 'box') do
              tag.p 'Narrow Column'
            end
          end

          c.column do
            c.tag.div(class: 'box') do
              tag.p 'Main Column'
            end
          end
        end
      end

      # Offset column
      def offset
        render Columns::Component.new do |c|
          c.column(class: 'is-half is-offset-one-quarter') do
            c.tag.div(class: 'box') do
              tag.p 'Offset column'
            end
          end
        end
      end

      # Multiline columns
      def multiline
        render Columns::Component.new(class: 'is-multiline') do |c|
          c.column(class: 'is-half') do
            c.tag.div(class: 'box') do
              tag.p '1st'
            end
          end

          c.column(class: 'is-half') do
            c.tag.div(class: 'box') do
              tag.p '2nd'
            end
          end

          c.column(class: 'is-one-third') do
            c.tag.div(class: 'box') do
              tag.p '3rd'
            end
          end

          c.column(class: 'is-two-thirds') do
            c.tag.div(class: 'box') do
              tag.p '4th'
            end
          end
        end
      end
    end
  end
end
