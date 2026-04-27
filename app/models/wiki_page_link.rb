class WikiPageLink < ActiveRecord::Base
  belongs_to :source_page, class_name: 'WikiPage'
  belongs_to :target_page, class_name: 'WikiPage'

  validates :source_page_id, presence: true
  validates :target_page_id, presence: true
  validates :source_page_id, uniqueness: { scope: :target_page_id }

  validate :no_self_links

  scope :for_source, ->(page) { where(source_page_id: page.id) }
  scope :for_target, ->(page) { where(target_page_id: page.id) }

  # Returns all pages linking TO the given page (backlinks)
  def self.backlinks_for(page)
    where(target_page_id: page.id)
      .includes(source_page: { wiki: :project })
      .order('wiki_pages.title ASC')
  end

  # Returns all pages linked FROM the given page (forward links)
  def self.forward_links_for(page)
    where(source_page_id: page.id)
      .includes(target_page: { wiki: :project })
      .order('wiki_pages.title ASC')
  end

  # Returns backlinks visible to the given user
  def self.visible_backlinks_for(page, user = User.current)
    backlinks_for(page).select do |link|
      link.source_page&.wiki&.project&.visible?(user)
    end
  end

  # Returns forward links visible to the given user
  def self.visible_forward_links_for(page, user = User.current)
    forward_links_for(page).select do |link|
      link.target_page&.wiki&.project&.visible?(user)
    end
  end

  private

  def no_self_links
    if source_page_id == target_page_id
      errors.add(:target_page_id, :invalid)
    end
  end
end
