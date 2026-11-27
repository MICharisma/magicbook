require "rails_helper"

RSpec.describe VisibleTaggedRecords do
  let!(:owner) do
    Mage.create!(
      email: "visible-tags-owner@example.com",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )
  end
  let!(:reader) do
    Mage.create!(
      email: "visible-tags-reader@example.com",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )
  end
  let!(:admin) do
    Mage.create!(
      admin: true,
      email: "visible-tags-admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )
  end
  let!(:tag) { Tag.create!(name: "Sleeper") }
  let!(:published_list) { List.create!(name: "Published list", mage: owner, privacy: :published) }
  let!(:draft_list) { List.create!(name: "Draft list", mage: owner, privacy: :draft) }
  let!(:published_item) { published_list.listed_items.create!(designation: "Published item", privacy: :published) }
  let!(:draft_item) { draft_list.listed_items.create!(designation: "Draft item", privacy: :draft) }

  before do
    published_item.taggings.create!(tag: tag, mage: owner)
    draft_item.taggings.create!(tag: tag, mage: owner)
    published_list.taggings.create!(tag: tag, mage: owner)
    draft_list.taggings.create!(tag: tag, mage: owner)
  end

  it "lets guests see only published lists and items" do
    visibility = described_class.new(nil)

    expect(visibility.listed_items_for(tag)).to contain_exactly(published_item)
    expect(visibility.lists_for(tag)).to contain_exactly(published_list)
    expect(visibility.counts_by_tag_id).to eq(tag.id => 2)
  end

  it "lets guests see unreviewed public lists, but not secrets" do
    secret_list = List.create!(name: "Secret list", mage: owner, privacy: :secret)
    unreviewed_list = List.create!(name: "Unreviewed list", mage: owner, privacy: :unreviewed)
    secret_list.taggings.create!(tag: tag, mage: owner)
    unreviewed_list.taggings.create!(tag: tag, mage: owner)

    visibility = described_class.new(nil)

    expect(visibility.lists_for(tag)).to contain_exactly(published_list, unreviewed_list)
  end

  it "lets an owner see their unpublished tagged records" do
    visibility = described_class.new(owner)

    expect(visibility.listed_items_for(tag)).to contain_exactly(published_item, draft_item)
    expect(visibility.lists_for(tag)).to contain_exactly(published_list, draft_list)
    expect(visibility.counts_by_tag_id).to eq(tag.id => 4)
  end

  it "does not leak another mage's drafts to a signed-in reader" do
    visibility = described_class.new(reader)

    expect(visibility.listed_items_for(tag)).to contain_exactly(published_item)
    expect(visibility.lists_for(tag)).to contain_exactly(published_list)
  end

  it "lets an admin see remaining tagged items and all tagged lists" do
    visibility = described_class.new(admin)

    expect(visibility.listed_items_for(tag)).to contain_exactly(published_item, draft_item)
    expect(visibility.lists_for(tag)).to contain_exactly(published_list, draft_list)
  end
end
