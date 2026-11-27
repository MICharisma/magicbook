class TagsController < ApplicationController
  def index
    authorize! :read, Tag

    @html_title = "Tags"
    @unstyled_tags = Tag.where(tag_context_id: nil).order(:name)
    @tag_contexts = TagContext.order(:name).includes(:tags)
    @counts = VisibleTaggedRecords.new(current_mage).counts_by_tag_id
  end

  def show
    @tag = Tag.includes(:tag_context).find(params[:id])
    authorize! :read, @tag

    visibility = VisibleTaggedRecords.new(current_mage)
    @html_title = [@tag.tag_context&.name, @tag.name].compact.join(": ")
    @listed_items = visibility.listed_items_for(@tag).includes(:list).order(:designation).page(params[:page]).per(48)
    @lists = visibility.lists_for(@tag).order(:name)
  end
end
