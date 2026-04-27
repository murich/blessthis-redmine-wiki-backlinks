namespace :bless_this_wiki_backlinks do
  desc 'Parse all existing wiki pages and populate backlinks table'
  task backfill: :environment do
    require_relative '../../lib/bless_this_redmine_wiki_backlinks/link_parser'

    puts "Starting wiki backlinks backfill..."
    puts "Clearing existing link records..."
    WikiPageLink.delete_all

    total_pages = WikiPage.count
    processed = 0
    errors = 0

    WikiPage.includes(:content, wiki: :project).find_each do |page|
      next unless page.content&.text.present?

      begin
        parsed = BlessThisRedmineWikiBacklinks::LinkParser.parse(page.content.text)
        resolved = BlessThisRedmineWikiBacklinks::LinkParser.resolve(parsed, page)

        resolved.each do |link|
          WikiPageLink.create!(
            source_page_id: page.id,
            target_page_id: link[:target_page].id,
            link_text: link[:link_text]
          )
        rescue ActiveRecord::RecordNotUnique
          # duplicate, skip
        end

        processed += 1
        print "\rProcessed #{processed}/#{total_pages} pages..."
      rescue => e
        errors += 1
        puts "\nError processing page '#{page.title}' (project: #{page.wiki&.project&.identifier}): #{e.message}"
      end
    end

    total_links = WikiPageLink.count
    puts "\n\nBackfill complete!"
    puts "  Pages processed: #{processed}"
    puts "  Errors: #{errors}"
    puts "  Link records created: #{total_links}"
  end

  desc 'Show backlink statistics'
  task stats: :environment do
    total_links = WikiPageLink.count
    total_pages = WikiPage.count

    pages_with_backlinks = WikiPageLink.select(:target_page_id).distinct.count
    pages_with_outlinks = WikiPageLink.select(:source_page_id).distinct.count

    most_linked = WikiPageLink.group(:target_page_id)
                              .count
                              .sort_by { |_, c| -c }
                              .first(10)

    puts "Wiki Backlinks Statistics"
    puts "=" * 40
    puts "  Total wiki pages:        #{total_pages}"
    puts "  Total link records:      #{total_links}"
    puts "  Pages with backlinks:    #{pages_with_backlinks}"
    puts "  Pages with outgoing:     #{pages_with_outlinks}"
    if total_pages > 0
      puts "  Avg links per page:      #{(total_links.to_f / total_pages).round(2)}"
    end

    if most_linked.any?
      puts "\nMost referenced pages:"
      most_linked.each do |page_id, count|
        page = WikiPage.find_by(id: page_id)
        next unless page

        project = page.wiki&.project&.identifier || '?'
        puts "  #{count} refs - #{page.title} (#{project})"
      end
    end
  end

  desc 'Remove all backlink records (clean slate)'
  task purge: :environment do
    count = WikiPageLink.count
    WikiPageLink.delete_all
    puts "Purged #{count} backlink records."
  end
end
