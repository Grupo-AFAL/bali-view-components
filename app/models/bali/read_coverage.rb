# frozen_string_literal: true

module Bali
  # #709 — how much of a record's audience has already acknowledged it:
  #
  #   coverage = Bali::ReadCoverage.new(@document, audience: @document.readers)
  #   coverage.coverage_percentage # => 75.0
  #   coverage.pending_users       # => [#<User ...>]
  #   coverage.below_threshold?    # => true
  #
  # The audience is INJECTED and the engine has no opinion on where it comes from. In
  # gobierno-corporativo it is built out of Workday::Worker, departments and readers; none
  # of that is transplantable, nor does it have to be. All that is asked of the users is
  # that they respond to `id` and have a class, to match the acknowledgment's polymorphic
  # pair.
  #
  # Nor does it group by area: that belongs to the host, which is the one that knows what an
  # area is.
  class ReadCoverage
    # 80 is the only value that exists in production today (gobierno-corporativo's
    # COMPLIANCE_THRESHOLD), but it lives here as a default and not as a shared constant:
    # the threshold is each app's own policy.
    DEFAULT_THRESHOLD = 80

    attr_reader :record, :audience, :threshold

    def initialize(record, audience:, threshold: DEFAULT_THRESHOLD)
      @record = record
      @audience = audience.to_a
      @threshold = threshold
    end

    def total_count = audience.size

    def confirmed_count = confirmed_users.size

    def pending_count = pending_users.size

    def confirmed_users = partitioned_audience.first

    def pending_users = partitioned_audience.last

    # nil, NOT 0, when there is no audience (decision 709-4). A record nobody has to read
    # is not 0% covered — its coverage is simply undefined, and 0/0 is not zero. Returning
    # 0.0 paints a dashboard red over documents that are nobody's business, and returning
    # 100.0 claims a coverage nobody confirmed; nil forces whoever renders to decide what
    # goes there ("—", "No audience"), which is the only honest way out. `below_threshold?`
    # still answers a boolean, so the compliance path does not break.
    def coverage_percentage
      return nil if total_count.zero?

      (confirmed_count * 100.0 / total_count).round(1)
    end

    # With no audience there is no breach: nobody is pending. Here too it parts from
    # gobierno-corporativo, which returns `true` and flags every record with no assigned
    # readers as non-compliant.
    def below_threshold?
      return false if total_count.zero?

      coverage_percentage < threshold
    end

    private

    # One query and one pass: `pluck` the polymorphic pair into a Set and partition in
    # memory. The audience arrives already materialized, so iterating it is free compared
    # with asking for each user.
    def partitioned_audience
      @partitioned_audience ||= audience.partition { |user| confirmed_keys.include?(key_for(user)) }
    end

    def confirmed_keys
      @confirmed_keys ||= record.acknowledgments.pluck(:user_type, :user_id).to_set
    end

    # `polymorphic_name` and not `class.name` so that an STI hierarchy matches what the
    # acknowledgment stored (which is the base class).
    def key_for(user)
      [ user.class.polymorphic_name, user.id ]
    end
  end
end
