# Bless This Redmine Wiki Backlinks

A Redmine plugin that automatically tracks wiki page cross-references and exposes them via UI and API. Shows which pages link to the current page ("Referenced by") and provides a JSON API for programmatic access.

Built for Redmine 6 (Rails 7) by [BlessThis.software](https://blessthis.software).

## Features

- **Automatic link tracking**: Parses `[[WikiLinks]]` on every wiki page save
- **Backlinks UI**: "Referenced by" section on wiki pages showing all linking pages
- **Cross-project links**: Tracks `[[project:PageName]]` references across projects
- **JSON API**: Dedicated endpoint for backlinks and forward links
- **Permission-aware**: Only shows links from projects visible to the current user
- **Bulk backfill**: Rake task to populate links for existing wiki content

## Requirements

- Redmine 5.0+ (tested on Redmine 6.0)
- Ruby 3.0+
- PostgreSQL, MySQL, or SQLite

## Installation

1. Clone the plugin into your Redmine plugins directory:
   ```bash
   cd /path/to/redmine/plugins
   git clone https://github.com/murich/blessthis-redmine-wiki-backlinks.git bless_this_redmine_wiki_backlinks
   ```

2. Run plugin migrations:
   ```bash
   bundle exec rake redmine:plugins:migrate RAILS_ENV=production
   ```

3. Restart Redmine

4. Backfill existing wiki pages (optional but recommended):
   ```bash
   bundle exec rake bless_this_wiki_backlinks:backfill RAILS_ENV=production
   ```

## Usage

### Wiki Page UI

After installation, a "Referenced by" section appears at the bottom of every wiki page that has incoming links. The section is collapsible and groups links by project when cross-project references exist.

### API

Get backlinks and forward links for a wiki page:

```bash
# Dedicated backlinks endpoint
curl -H "X-Redmine-API-Key: YOUR_KEY" \
  "https://redmine.example.com/projects/my-project/wiki_backlinks/PageName.json"
```

Response:
```json
{
  "wiki_page": {
    "title": "PageName",
    "forward_links": [
      {
        "page_title": "OtherPage",
        "link_text": "link display text",
        "project": "my-project"
      }
    ],
    "backlinks": [
      {
        "page_title": "SomePage",
        "link_text": "PageName",
        "project": "my-project"
      }
    ]
  }
}
```

### Supported Link Formats

| Format | Description |
|--------|-------------|
| `[[PageName]]` | Internal wiki link |
| `[[PageName\|Display Text]]` | Link with custom display text |
| `[[project-id:PageName]]` | Cross-project wiki link |

### Rake Tasks

```bash
# Parse all existing wiki pages and create link records
bundle exec rake bless_this_wiki_backlinks:backfill RAILS_ENV=production

# Show backlink statistics
bundle exec rake bless_this_wiki_backlinks:stats RAILS_ENV=production

# Remove all backlink records
bundle exec rake bless_this_wiki_backlinks:purge RAILS_ENV=production
```

## How It Works

1. **On wiki page save**: The plugin hooks into `WikiContent.after_save` to parse the page content for `[[WikiLink]]` patterns
2. **Link diffing**: Compares parsed links against stored records - inserts new links, removes deleted ones, updates changed display text
3. **Page deletion**: Foreign key cascades automatically clean up link records when pages are deleted
4. **Permissions**: Backlinks from projects not visible to the current user are filtered out

## Uninstallation

1. Rollback plugin migrations:
   ```bash
   bundle exec rake redmine:plugins:migrate NAME=bless_this_redmine_wiki_backlinks VERSION=0 RAILS_ENV=production
   ```

2. Remove the plugin directory:
   ```bash
   rm -rf /path/to/redmine/plugins/bless_this_redmine_wiki_backlinks
   ```

3. Restart Redmine

## License

MIT License. See [LICENSE](LICENSE) for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Related

- [Bless This Redmine SSO](https://github.com/murich/bless-this-redmine-sso) - OAuth/SSO plugin for Redmine
- [Redmine Feature Request #3879](https://www.redmine.org/issues/3879) - Original 2009 backlinks feature request
