class CreateWikiPageLinks < ActiveRecord::Migration[7.2]
  def change
    create_table :wiki_page_links do |t|
      t.integer :source_page_id, null: false
      t.integer :target_page_id, null: false
      t.string :link_text, limit: 255
      t.timestamps
    end

    add_foreign_key :wiki_page_links, :wiki_pages, column: :source_page_id, on_delete: :cascade
    add_foreign_key :wiki_page_links, :wiki_pages, column: :target_page_id, on_delete: :cascade

    add_index :wiki_page_links, [:source_page_id, :target_page_id],
              unique: true, name: 'idx_wiki_link_pair'
    add_index :wiki_page_links, :target_page_id, name: 'idx_wiki_link_target'
    add_index :wiki_page_links, :source_page_id, name: 'idx_wiki_link_source'
  end
end
