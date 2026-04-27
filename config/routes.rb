RedmineApp::Application.routes.draw do
  # API endpoint: GET /projects/:project_id/wiki_backlinks/:id.json
  get 'projects/:project_id/wiki_backlinks/:id', to: 'wiki_backlinks#show', as: 'project_wiki_backlinks'
end
