module BlessThisRedmineWikiBacklinks
  class Hooks < Redmine::Hook::ViewListener
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
        <script>
        document.addEventListener('DOMContentLoaded', function() {
          var match = window.location.pathname.match(/\\/projects\\/([^\\/]+)\\/wiki\\/([^\\/]+)$/);
          if (!match) {
            match = window.location.pathname.match(/\\/projects\\/([^\\/]+)\\/wiki\\/?$/);
            if (match) match = [null, match[1], 'Wiki'];
          }
          if (!match) return;

          var projectId = match[1];
          var pageTitle = match[2];
          var apiUrl = '/projects/' + projectId + '/wiki_backlinks/' + pageTitle + '.json';

          var xhr = new XMLHttpRequest();
          xhr.open('GET', apiUrl);
          xhr.setRequestHeader('Accept', 'application/json');
          xhr.onload = function() {
            if (xhr.status !== 200) return;
            try {
              var data = JSON.parse(xhr.responseText);
              var backlinks = data.wiki_page.backlinks;
              if (!backlinks || backlinks.length === 0) return;

              var grouped = {};
              backlinks.forEach(function(bl) {
                var proj = bl.project;
                if (!grouped[proj]) grouped[proj] = [];
                grouped[proj].push(bl);
              });

              var projectKeys = Object.keys(grouped);
              var multiProject = projectKeys.length > 1;

              var html = '<div id="wiki-backlinks" class="wiki-backlinks-section"><hr />';
              html += '<fieldset class="collapsible">';
              html += '<legend onclick="toggleFieldset(this);">';
              html += '<span>Referenced by (' + backlinks.length + ')</span>';
              html += '</legend><div><ul class="wiki-backlinks-list">';

              projectKeys.forEach(function(proj) {
                if (multiProject) {
                  html += '<li class="wiki-backlinks-project"><strong>' + escapeHtml(proj) + '</strong><ul>';
                }
                grouped[proj].forEach(function(bl) {
                  var title = bl.page_title.replace(/_/g, ' ');
                  var url = '/projects/' + bl.project + '/wiki/' + bl.page_title;
                  html += '<li><a href="' + url + '">' + escapeHtml(title) + '</a>';
                  if (bl.link_text && bl.link_text !== bl.page_title) {
                    html += ' &mdash; <em>' + escapeHtml(bl.link_text) + '</em>';
                  }
                  html += '</li>';
                });
                if (multiProject) {
                  html += '</ul></li>';
                }
              });

              html += '</ul></div></fieldset></div>';

              var wikiUpdate = document.querySelector('.wiki-update-info');
              if (wikiUpdate) {
                wikiUpdate.insertAdjacentHTML('beforebegin', html);
              }
            } catch(e) {
              console.warn('[WikiBacklinks] Error:', e);
            }
          };
          xhr.send();

          function escapeHtml(text) {
            var div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
          }
        });
        </script>
      HTML
    end
  end
end
