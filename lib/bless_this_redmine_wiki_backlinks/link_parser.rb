module BlessThisRedmineWikiBacklinks
  class LinkParser
    # Matches [[PageName]] and [[PageName|Display Text]]
    WIKI_LINK_PATTERN = /\[\[([^\]\|]+?)(?:\|([^\]]*))?\]\]/

    # Parse wiki content text and return array of link hashes
    # Each hash: { page_title: String, link_text: String, project_identifier: String|nil }
    def self.parse(text)
      return [] if text.blank?

      links = []
      text.scan(WIKI_LINK_PATTERN) do |target, display_text|
        target = target.strip
        next if target.blank?

        project_identifier = nil
        page_title = target

        # Handle cross-project links: [[project:PageName]]
        if target.include?(':')
          parts = target.split(':', 2)
          # Distinguish from namespaced macros (e.g., {{include(...)}} )
          # and URLs (http:, https:, ftp:)
          unless parts[0] =~ /\A(https?|ftp|mailto)\z/i
            project_identifier = parts[0].strip
            page_title = parts[1].strip
          end
        end

        next if page_title.blank?

        # Normalize page title: Redmine uses underscores internally
        page_title = page_title.tr(' ', '_') if page_title.include?(' ')

        links << {
          page_title: page_title,
          link_text: (display_text || page_title).strip,
          project_identifier: project_identifier
        }
      end

      # Deduplicate by page_title + project_identifier (keep first occurrence)
      links.uniq { |l| [l[:project_identifier], l[:page_title]] }
    end

    # Resolve parsed links to WikiPage records for a given source page
    def self.resolve(parsed_links, source_page)
      return [] if parsed_links.empty? || source_page.nil?

      source_wiki = source_page.wiki
      return [] if source_wiki.nil?

      resolved = []

      parsed_links.each do |link|
        target_page = find_target_page(link, source_wiki)
        next if target_page.nil?
        next if target_page.id == source_page.id # skip self-links

        resolved << {
          target_page: target_page,
          link_text: link[:link_text]
        }
      end

      resolved
    end

    def self.find_target_page(link, source_wiki)
      if link[:project_identifier].present?
        # Cross-project link
        project = Project.find_by(identifier: link[:project_identifier])
        return nil if project.nil? || project.wiki.nil?

        project.wiki.find_page(link[:page_title])
      else
        # Same-project link
        source_wiki.find_page(link[:page_title])
      end
    rescue => e
      Rails.logger.warn "[WikiBacklinks] Error resolving link #{link.inspect}: #{e.message}"
      nil
    end
  end
end
