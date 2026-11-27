class VisibleTaggedRecords
  def initialize(mage)
    @mage = mage
  end

  def lists_for(tag)
    tag.lists.merge(visible_lists)
  end

  def listed_items_for(tag)
    tag.listed_items.merge(visible_listed_items)
  end

  def counts_by_tag_id
    list_counts = Tagging.where(taggable_type: "List", taggable_id: visible_lists.select(:id)).group(:tag_id).count
    item_counts = Tagging.where(taggable_type: "ListedItem", taggable_id: visible_listed_item_ids).group(:tag_id).count
    list_counts.merge(item_counts) { |_tag_id, lists, items| lists + items }
  end

  def visible_lists
    if @mage&.admin?
      List.all
    elsif @mage
      List.where(privacy: [:unreviewed, :published])
        .or(List.where(mage_id: @mage.id, privacy: [:draft, :unreviewed, :unreviewed_secret, :published, :secret]))
    else
      List.visible
    end
  end

  def visible_listed_items
    ListedItem.where(id: visible_listed_item_ids)
  end

  private

  def visible_listed_item_ids
    if @mage&.admin?
      ListedItem.remaining.select(:id)
    elsif @mage
      own = ListedItem.remaining.joins(:list).where(lists: { mage_id: @mage.id }).select("listed_items.id")
      others = ListedItem.for_others.joins(:list).merge(List.visible).select("listed_items.id")
      ListedItem.where(id: own).or(ListedItem.where(id: others)).select(:id)
    else
      ListedItem.published.joins(:list).merge(List.visible).select("listed_items.id")
    end
  end
end
