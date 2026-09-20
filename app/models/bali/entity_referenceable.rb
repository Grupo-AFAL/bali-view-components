# frozen_string_literal: true

module Bali
  # #708 — marks a model whose BlockNote content can embed references to other entities
  # (`@`/`#` in the editor). On save, the references in the JSON are materialized into
  # `bali_entity_references`.
  #
  #   class Document < ApplicationRecord
  #     include Bali::EntityReferenceable
  #     references_entities_in :body   # optional; defaults to :content
  #   end
  #
  # Which types are referenceable is decided by `Bali.entity_reference_types` (the same
  # registry that feeds the search and the JS `references_config`): a reference to an
  # unregistered type is ignored while extracting, so a retired type stops being
  # materialized without a data migration.
  module EntityReferenceable
    extend ActiveSupport::Concern

    included do
      has_many :entity_references, class_name: "Bali::EntityReference",
                                   as: :record, dependent: :destroy

      # The name of the JSON column, so that `references_entities_in` does not have to
      # redefine the callback. `instance_writer: false`: it is class configuration.
      class_attribute :entity_reference_attribute, instance_writer: false, default: :content

      # ONLY when the content changed. The editor autosaves, and without this guard every
      # save would delete and recreate the whole document's references.
      after_save :extract_entity_references!, if: :entity_reference_source_changed?
    end

    class_methods do
      # Declares which column holds the BlockNote JSON when it is not `content`.
      def references_entities_in(attribute)
        self.entity_reference_attribute = attribute.to_sym
      end

      # The records of THIS class that reference `entity`.
      def referencing(entity)
        joins(:entity_references)
          .where(bali_entity_references: { referenceable_type: entity.class.name,
                                           referenceable_id: entity.id })
          .distinct
      end
    end

    # The references pointing at this record (the inverse of `entity_references`).
    def incoming_references
      Bali::EntityReference.to(self)
    end

    # Minimal diff against the existing rows: deletes the ones that are gone, inserts the
    # new ones, and DOES NOT TOUCH the ones that stay — their ids survive every autosave,
    # which is what makes it possible to hang things off a reference (and what a
    # delete_all + create! would break).
    def extract_entity_references!
      extracted = extracted_entity_references
      extracted_keys = extracted.map { |ref| [ ref[:type], ref[:id].to_i ] }.to_set

      current = entity_references.pluck(:id, :referenceable_type, :referenceable_id)
      stale_ids = current.reject { |(_, type, ref_id)| extracted_keys.include?([ type, ref_id ]) }.map(&:first)
      current_keys = current.map { |(_, type, ref_id)| [ type, ref_id ] }.to_set
      new_rows = extracted.reject { |ref| current_keys.include?([ ref[:type], ref[:id].to_i ]) }

      transaction do
        entity_references.where(id: stale_ids).delete_all if stale_ids.any?
        insert_entity_references(new_rows) if new_rows.any?
      end
    end

    private

    def entity_reference_source_changed?
      saved_change_to_attribute?(self.class.entity_reference_attribute)
    end

    # The content is written by the editor: nothing guarantees that a node points at a live
    # type, nor at an id that fits in the column, nor that the document carries a reasonable
    # number of references. The three limits below exist because this callback runs INSIDE
    # the host's `update!` — whatever blows up here takes the user's save down with it.
    #
    #   - outside the registry          → ignored (a retired type stops being indexed)
    #   - non-numeric id or over bigint → ignored (a `to_i` would store garbage, and a
    #                                     20-digit id raises RangeError and aborts the save)
    #   - more than MAX_REFERENCES      → truncated (a document with 12k references blows
    #                                     past PG's bind-param ceiling in a single insert)
    NUMERIC_ID = /\A\d{1,19}\z/
    BIGINT_MAX = (2**63) - 1
    MAX_REFERENCES = 500
    MAX_REFERENCE_TEXT = 255

    def extracted_entity_references
      content = public_send(self.class.entity_reference_attribute)
      return [] if content.blank?

      registered = Bali.entity_reference_types.keys.map(&:to_s)
      Bali::BlockNote::Text
        .entity_references(Bali::BlockNote::Text.normalize(content))
        .select { |ref| registered.include?(ref[:type]) && storable_id?(ref[:id]) }
        .first(MAX_REFERENCES)
    end

    def storable_id?(id)
      id.match?(NUMERIC_ID) && id.to_i <= BIGINT_MAX
    end

    def insert_entity_references(rows)
      now = Time.current

      # `insert_all` (no bang) + `unique_by`: two overlapping autosaves of the same record
      # read the same `current` and compute the same new rows; with the bang the loser of the
      # race raises RecordNotUnique inside the after_save and throws away a legitimate save.
      # Skipping the conflict IS the semantics of the diff — the row already there keeps its id.
      # (`unique_by` needs Postgres or SQLite; a host on MySQL would have to override this.)
      entity_references.insert_all(
        rows.map { |ref|
          {
            record_type: self.class.polymorphic_name,
            record_id: id,
            referenceable_type: ref[:type],
            referenceable_id: ref[:id],
            # Client text, not validated against the real record: it is capped so that a
            # 200 KB `entityName` is not stored whole. See docs/guides/engines.md — it is
            # the only part of this table that does NOT go through `permission_scope`.
            reference_text: ref[:name].to_s.truncate(MAX_REFERENCE_TEXT).presence,
            created_at: now,
            updated_at: now
          }
        },
        unique_by: %i[record_type record_id referenceable_type referenceable_id]
      )
    end
  end
end
