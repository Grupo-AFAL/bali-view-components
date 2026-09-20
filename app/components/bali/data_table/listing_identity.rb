# frozen_string_literal: true

module Bali
  module DataTable
    # The listing's identity, shared by the controls that persist anything. The DataTable
    # resolves it ONCE and the two shapes the JS consumes are derived here. Each control used
    # to normalize the "#" on its own, and the saved-views controller locates the column
    # selector by comparing the EXACT string of the attribute: two separate derivations
    # described different listings, and saving a view lost the columns without failing
    # anywhere.
    module ListingIdentity
      # The id of the CONTAINER the DataTable paints, derivable WITHOUT building the
      # component. It is what a `.turbo_stream.erb` has to target: there the host has the
      # filter_form but not the DataTable, and targeting the RAW `storage_id` failed in
      # silence every time sanitizing changed the value — Turbo resolves the target with
      # getElementById, so with no node it replaces nothing, does not blow up and does not
      # log.
      #
      #   turbo_stream.replace Bali::DataTable::ListingIdentity.for(@filter_form)
      #
      # @param source [#storage_id, String, Symbol] the filter_form or the raw value
      def self.for(source)
        sanitize(source.respond_to?(:storage_id) ? source.storage_id : source)
      end

      # Slug usable as a CSS identifier: no leading "#", no invalid characters and not
      # starting with a digit — `#123 table` makes querySelector throw a SyntaxError. No
      # downcase on purpose: `#id` matching in HTML is case-sensitive.
      def self.sanitize(value)
        slug = value.to_s.delete_prefix("#").gsub(/[^A-Za-z0-9_-]+/, "-").gsub(/\A-+|-+\z/, "")
        return if slug.blank?

        slug.match?(/\A\d/) ? "listing-#{slug}" : slug
      end

      # Points at the DataTable's CONTAINER, not at the <table>: the table may carry no id of
      # its own and the container is the only node whose identity the listing knows.
      def table_selector
        listing_id.presence && "##{listing_id} table"
      end

      def columns_storage_key
        listing_id.presence && "bali:columns:#{listing_id}"
      end
    end
  end
end
