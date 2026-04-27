RedmineApp::Application.routes.draw do
  # API endpoint (requires X-Redmine-API-Key)
  get 'projects/:project_id/wiki_backlinks/:id', to: 'wiki_backlinks#show',
      as: 'project_wiki_backlinks'

  # UI endpoint (session-authenticated, for browser JS)
  get 'projects/:project_id/wiki_backlinks_data/:id', to: 'wiki_backlinks#show_for_ui',
      as: 'project_wiki_backlinks_data'
end
