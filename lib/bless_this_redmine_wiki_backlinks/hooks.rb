module BlessThisRedmineWikiBacklinks
  class Hooks < Redmine::Hook::ViewListener
    # Inject "Referenced by" section below wiki page content
    def view_wiki_show_bottom(context = {})
      page = context[:page]
      return '' if page.nil?

      backlinks = WikiPageLink.visible_backlinks_for(page, User.current)
      return '' if backlinks.empty?

      # Group backlinks by project
      grouped = backlinks.group_by { |link| link.source_page.wiki.project }

      controller = context[:controller]
      current_project = page.wiki.project

      html = <<~HTML
        <div id="wiki-backlinks" class="wiki-backlinks-section">
          <hr />
          <fieldset class="collapsible">
            <legend onclick="toggleFieldset(this);">
              <span>#{I18n.t(:label_referenced_by, scope: :bless_this_wiki_backlinks, default: 'Referenced by')} (#{backlinks.size})</span>
            </legend>
            <div>
              <ul class="wiki-backlinks-list">
      HTML

      grouped.each do |project, links|
        if grouped.size > 1
          html << "    <li class=\"wiki-backlinks-project\"><strong>#{ERB::Util.html_escape(project.name)}</strong><ul>"
        end

        links.each do |link|
          source = link.source_page
          title = ERB::Util.html_escape(source.title.tr('_', ' '))
          link_text_display = ''
          if link.link_text.present? && link.link_text != source.title
            link_text_display = " &mdash; <em>#{ERB::Util.html_escape(link.link_text)}</em>"
          end

          if project == current_project
            url = controller.url_for(controller: 'wiki', action: 'show',
                                     project_id: project.identifier,
                                     id: source.title, only_path: true)
          else
            url = controller.url_for(controller: 'wiki', action: 'show',
                                     project_id: project.identifier,
                                     id: source.title, only_path: true)
          end

          html << "      <li><a href=\"#{url}\">#{title}</a>#{link_text_display}</li>\n"
        end

        if grouped.size > 1
          html << "    </ul></li>"
        end
      end

      html << <<~HTML
              </ul>
            </div>
          </fieldset>
        </div>
      HTML

      html.html_safe
    end

    # Add CSS for backlinks section
    def view_layouts_base_html_head(context = {})
      <<~HTML.html_safe
        <style>
          .wiki-backlinks-section { margin-top: 1em; }
          .wiki-backlinks-section fieldset { border: 1px solid #e4e4e4; }
          .wiki-backlinks-section legend { cursor: pointer; font-weight: bold; }
          .wiki-backlinks-list { margin: 0.5em 0; padding-left: 1.5em; }
          .wiki-backlinks-list li { margin: 0.2em 0; }
          .wiki-backlinks-project > ul { margin-top: 0.3em; }
        </style>
      HTML
    end
  end
end
