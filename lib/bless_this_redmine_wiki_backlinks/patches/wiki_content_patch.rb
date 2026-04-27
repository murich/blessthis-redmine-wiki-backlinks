require_relative '../link_parser'

module BlessThisRedmineWikiBacklinks
  module Patches
    module WikiContentPatch
      def self.included(base)
        base.class_eval do
          after_save :update_wiki_backlinks
        end
      end

      private

      def update_wiki_backlinks
        page = self.page
        return if page.nil?

        parsed_links = BlessThisRedmineWikiBacklinks::LinkParser.parse(self.text)
        resolved_links = BlessThisRedmineWikiBacklinks::LinkParser.resolve(parsed_links, page)

        # Build set of desired target_page_id => link_text
        desired = {}
        resolved_links.each do |link|
          desired[link[:target_page].id] = link[:link_text]
        end

        existing = WikiPageLink.for_source(page).to_a
        existing_map = existing.each_with_object({}) { |l, h| h[l.target_page_id] = l }

        # Delete removed links
        to_delete = existing_map.keys - desired.keys
        WikiPageLink.where(source_page_id: page.id, target_page_id: to_delete).delete_all if to_delete.any?

        # Insert new links, update changed link_text
        desired.each do |target_id, link_text|
          if existing_map.key?(target_id)
            record = existing_map[target_id]
            if record.link_text != link_text
              record.update_columns(link_text: link_text, updated_at: Time.current)
            end
          else
            WikiPageLink.create!(
              source_page_id: page.id,
              target_page_id: target_id,
              link_text: link_text
            )
          end
        end
      rescue => e
        Rails.logger.error "[WikiBacklinks] Error updating links for page #{page&.title}: #{e.message}"
        Rails.logger.error e.backtrace.first(5).join("\n")
      end
    end
  end
end

unless WikiContent.included_modules.include?(BlessThisRedmineWikiBacklinks::Patches::WikiContentPatch)
  WikiContent.send(:include, BlessThisRedmineWikiBacklinks::Patches::WikiContentPatch)
end
