class AddDocumentIdToBlockEditorThreads < ActiveRecord::Migration[8.0]
  def change
    add_reference :block_editor_threads, :document, null: true, foreign_key: true
  end
end
