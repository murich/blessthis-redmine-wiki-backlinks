class WikiBacklinksController < ApplicationController
  before_action :find_optional_project
  before_action :find_wiki_page
  accept_api_auth :show

  # API endpoint: GET /projects/:project_id/wiki_backlinks/:id.json
  # Authenticated via X-Redmine-API-Key header
  def show
    render json: backlinks_data
  end

  # UI endpoint: GET /projects/:project_id/wiki_backlinks_data/:id
  # Authenticated via browser session (no .json extension needed)
  def show_for_ui
    render json: backlinks_data
  end

  private

  def backlinks_data
    backlinks = WikiPageLink.visible_backlinks_for(@wiki_page, User.current)
    forward_links = WikiPageLink.visible_forward_links_for(@wiki_page, User.current)

    {
      wiki_page: {
        title: @wiki_page.title,
        forward_links: forward_links.map { |link|
          {
            page_title: link.target_page.title,
            link_text: link.link_text,
            project: link.target_page.wiki.project.identifier
          }
        },
        backlinks: backlinks.map { |link|
          {
            page_title: link.source_page.title,
            link_text: link.link_text,
            project: link.source_page.wiki.project.identifier
          }
        }
      }
    }
  end

  def find_wiki_page
    return render_404 unless @project&.wiki

    page_title = params[:page_id] || params[:id] || 'Wiki'
    @wiki_page = @project.wiki.find_page(page_title)

    render_404 unless @wiki_page
  end
end
