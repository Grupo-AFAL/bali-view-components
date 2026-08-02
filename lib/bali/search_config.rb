# frozen_string_literal: true

module Bali
  # The one shape a `search:` option takes, whichever surface receives it.
  #
  # There used to be two. The Filters panel asked for `fields:` and derived the
  # Ransack parameter itself; SimpleFilters asked for a `field_name:` the caller
  # had already written out ("q[name_cont]"). The same listing therefore needed
  # two different hashes depending on which of the two filter surfaces it
  # rendered, FilterForm shipped a builder for each, and only one of them
  # carried `icon:` while only the other carried `fields:` -- so moving a
  # listing from one surface to the other silently dropped options.
  #
  # Only `fields:` is accepted now: the columns are what the caller knows, and
  # the parameter name is what Bali derives from them (see RansackParamName).
  class SearchConfig
    KEYS = %i[fields value placeholder label icon width].freeze

    attr_reader :fields, :value, :placeholder, :label, :icon, :width

    # Accepts nil, a Hash or an already-built config, so a component can wrap
    # whatever it was handed without branching on the type first.
    def self.wrap(search)
      return search if search.is_a?(self)

      new(**(search || {}).to_h.symbolize_keys)
    end

    def initialize(**options)
      validate!(options)

      @fields = Array(options[:fields]).reject { |field| field.to_s.empty? }
      @value = options[:value]
      @placeholder = options[:placeholder]
      @label = options[:label]
      @icon = options[:icon]
      @width = options[:width]
    end

    def enabled?
      fields.any?
    end

    # "name_or_genre_cont"
    def predicate
      RansackParamName.predicate(fields)
    end

    # "q[name_or_genre_cont]"
    def param_name
      RansackParamName.param(fields)
    end

    def to_h
      { fields: fields, value: value, placeholder: placeholder,
        label: label, icon: icon, width: width }
    end

    private

    # Raising beats ignoring: a misspelled key here does not break the page, it
    # renders a search box that quietly searches nothing, which is exactly the
    # failure the old two-shape API produced on its own.
    def validate!(options)
      unknown = options.keys - KEYS
      return if unknown.empty?

      raise ArgumentError, "#{unknown_message(unknown)}#{field_name_hint(unknown)}"
    end

    def unknown_message(unknown)
      "Unknown search option#{'s' if unknown.size > 1}: #{unknown.map(&:inspect).join(', ')}. " \
        "Known options are #{KEYS.map(&:inspect).join(', ')}."
    end

    def field_name_hint(unknown)
      return unless unknown.include?(:field_name)

      " Pass the columns and let Bali build the Ransack parameter: " \
        'field_name: "q[name_or_email_cont]" becomes fields: [:name, :email].'
    end
  end
end
