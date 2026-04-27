module BlessThisRedmineWikiBacklinks
  module Patches
    module WikiPagePatch
      def self.included(base)
        base.class_eval do
          has_many :outgoing_links, class_name: 'WikiPageLink',
                   foreign_key: :source_page_id, dependent: :delete_all
          has_many :incoming_links, class_name: 'WikiPageLink',
                   foreign_key: :target_page_id, dependent: :delete_all

          has_many :linked_pages, through: :outgoing_links,
                   source: :target_page
          has_many :linking_pages, through: :incoming_links,
                   source: :source_page

          after_destroy :cleanup_orphaned_links
        end
      end

      # Backlinks visible to the given user
      def visible_backlinks(user = User.current)
        WikiPageLink.visible_backlinks_for(self, user)
      end

      # Forward links visible to the given user
      def visible_forward_links(user = User.current)
        WikiPageLink.visible_forward_links_for(self, user)
      end

      private

      def cleanup_orphaned_links
        # dependent: :delete_all handles this, but just in case
        WikiPageLink.where(source_page_id: id).delete_all
        WikiPageLink.where(target_page_id: id).delete_all
      end
    end
  end
end

unless WikiPage.included_modules.include?(BlessThisRedmineWikiBacklinks::Patches::WikiPagePatch)
  WikiPage.send(:include, BlessThisRedmineWikiBacklinks::Patches::WikiPagePatch)
end
