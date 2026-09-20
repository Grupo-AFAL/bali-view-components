# frozen_string_literal: true

module Bali
  # #707 — content history for a host model:
  #
  #   class Document < ApplicationRecord
  #     include Bali::ContentVersionable
  #     content_versionable attribute: :content, coalesce_window: 5.minutes
  #   end
  #
  # The macro is optional: `include` on its own already applies the defaults (`:content`,
  # 5 minutes).
  #
  # The coalescing window is a parameter of the MODEL, not global config: how long an
  # "editing session" lasts depends on what is being edited, not on the app.
  #
  # Mind the split of responsibilities: the engine does NOT create versions on autosave. The
  # autosave PATCH goes to the host's URL (`document_editor/index.js`), so it is the host
  # that calls `create_or_coalesce_version!` in its `update`. The engine only reads
  # (index/show) and restores — see `Bali::ContentVersionsController`.
  module ContentVersionable
    extend ActiveSupport::Concern

    DEFAULT_COALESCE_WINDOW = 5.minutes

    included do
      class_attribute :content_version_attribute, instance_writer: false, default: :content
      class_attribute :content_version_coalesce_window, instance_writer: false,
                                                        default: DEFAULT_COALESCE_WINDOW

      has_many :content_versions, -> { order(version_number: :asc) },
               class_name: "Bali::ContentVersion", as: :record, dependent: :destroy
    end

    class_methods do
      # Configuration only: the association is declared in `included` so that calling the
      # macro twice (or not at all) does not register `dependent: :destroy` twice.
      def content_versionable(attribute: :content, coalesce_window: DEFAULT_COALESCE_WINDOW)
        self.content_version_attribute = attribute.to_sym
        self.content_version_coalesce_window = coalesce_window
      end
    end

    def current_content_version_number
      content_versions.maximum(:version_number) || 0
    end

    # Under the same lock as the coalescing, and for the same reason: another write fits
    # between reading the highest number and writing the next one. Without the lock it fails
    # closed (the unique index rejects the duplicate), but this is the method hosts call from
    # their `create`/`update`, so the failure mode was a 500 in a race.
    #
    # Side effect, and it is the desirable one: Rails refuses to lock a record with unsaved
    # changes, so versioning in the middle of an unpersisted edit now fails loudly instead
    # of storing a version that claims content the database never saw. This has to be called
    # AFTER the `save`, which is what the dummy and gobierno-corporativo already did.
    # `create_or_coalesce_version!` behaved this way from the start; now the two agree.
    def create_version!(author_name:, author: nil, summary: nil, metadata: nil)
      with_lock do
        content_versions.create!(
          content: versioned_content,
          version_number: current_content_version_number + 1,
          author: author,
          author_name: author_name,
          summary: summary,
          metadata: metadata || {}
        )
      end
    end

    # A burst of autosaves by the same author produces ONE version, not twelve: inside the
    # window the last one is updated instead of creating another.
    #
    # `with_lock` is not decoration — two concurrent autosaves would read the same "last
    # version" and create two rows with the same `version_number`, which the unique index
    # rejects. It is gobierno-corporativo's pattern; the dummy's lock-less implementation
    # was the bug, not the pattern.
    def create_or_coalesce_version!(author_name:, author: nil, summary: nil, metadata: nil)
      with_lock do
        last = content_versions.newest_first.first

        if last && last.same_author?(author, author_name) &&
           last.created_at > content_version_coalesce_window.ago
          # `summary` only overwrites when one is given: autosave sends none, and assigning
          # nil would silently erase the name the version already had ("Initial draft").
          attributes = { content: versioned_content }
          attributes[:summary] = summary if summary
          attributes[:metadata] = metadata if metadata
          last.update!(attributes)
          last
        else
          create_version!(author_name: author_name, author: author,
                          summary: summary, metadata: metadata)
        end
      end
    end

    def content_at_version(version_number)
      content_versions.find_by(version_number: version_number)&.content
    end

    # Restoring leaves a trail: the content comes back and a new version is born saying
    # where it came from. No extra "before restoring" version is stored because the host's
    # autosave already keeps the last version up to date with the live content — the head of
    # the history IS the previous state.
    #
    # The default `summary` is translated at restore time and STORED as text: it is a
    # historical fact, not a view. A host serving several languages that prefers to resolve
    # it at render time passes its own.
    def restore_content_version!(version, author_name:, author: nil, summary: nil)
      # Re-scoped ALWAYS, an object argument included: taking it as given let the content
      # of ANY other record's version be copied over this one. The controller already looked
      # inside `@record.content_versions`, but this is a public API of the model and a host
      # that brings the version from somewhere else deserved a RecordNotFound, not a silent
      # restore of someone else's content.
      version = content_versions.find(version.is_a?(Bali::ContentVersion) ? version.id : version)

      with_lock do
        update!(content_version_attribute => version.content)
        create_version!(
          author_name: author_name,
          author: author,
          summary: summary || I18n.t("bali_view.content_versions.restored_from",
                                     number: version.version_number)
        )
      end
    end

    private

    def versioned_content
      public_send(content_version_attribute)
    end
  end
end
