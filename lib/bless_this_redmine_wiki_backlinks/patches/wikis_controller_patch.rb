module BlessThisRedmineWikiBacklinks
  module Patches
    module WikisControllerPatch
      def self.included(base)
        base.class_eval do
          prepend InstanceMethods
          helper_method :wiki_backlinks_included?
        end
      end

      module InstanceMethods
        def show
          super
          # After the standard show action, load backlinks for the page
          if @page && params[:include]&.include?('backlinks')
            @wiki_backlinks = WikiPageLink.visible_backlinks_for(@page, User.current)
            @wiki_forward_links = WikiPageLink.visible_forward_links_for(@page, User.current)
          end
        end
      end

      private

      def wiki_backlinks_included?
        params[:include]&.include?('backlinks')
      end
    end
  end
end

unless WikiController.included_modules.include?(BlessThisRedmineWikiBacklinks::Patches::WikisControllerPatch)
  WikiController.send(:include, BlessThisRedmineWikiBacklinks::Patches::WikisControllerPatch)
end
