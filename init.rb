Redmine::Plugin.register :bless_this_redmine_wiki_backlinks do
  name 'Bless This Redmine Wiki Backlinks'
  author 'Andrii Murashkin'
  description 'Track wiki page cross-references and expose backlinks via UI and API. ' \
              'Automatically parses [[WikiLinks]] on save and shows "Referenced by" sections.'
  version '1.0.0'
  url 'https://github.com/murich/blessthis-redmine-wiki-backlinks'
  author_url 'https://blessthis.software'

  requires_redmine version_or_higher: '5.0.0'

  # Public permission — anyone who can view wiki pages can see backlinks
  permission :view_wiki_backlinks, {
    wiki_backlinks: [:show, :show_for_ui]
  }, public: true, read: true
end

Rails.application.config.to_prepare do
  require_relative 'lib/bless_this_redmine_wiki_backlinks/hooks'
  require_relative 'lib/bless_this_redmine_wiki_backlinks/patches/wiki_content_patch'
  require_relative 'lib/bless_this_redmine_wiki_backlinks/patches/wiki_page_patch'
  require_relative 'lib/bless_this_redmine_wiki_backlinks/patches/wikis_controller_patch'
end
