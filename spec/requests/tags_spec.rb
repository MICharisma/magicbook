require "rails_helper"

RSpec.describe "Tags", type: :request do
  include Devise::Test::IntegrationHelpers

  let!(:owner) do
    Mage.create!(
      email: "tag-index-owner@example.com",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )
  end
  let!(:format) { TagContext.create!(name: "Format", slug: "format", kind: "user") }
  let!(:commander) { format.tags.create!(name: "Commander", slug: "commander", kind: "user") }
  let!(:sleeper) { Tag.create!(name: "Sleeper") }
  let!(:list) { List.create!(name: "Published tagged list", mage: owner, privacy: :published) }

  before do
    host! "localhost"
    create_featured_book!
  end

  it "lists tags by style and links each tag to its page" do
    get tags_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Tags", "Format", "Commander", "No style", "Sleeper")
    expect(response.body).to include(tag_path(commander), tag_path(sleeper))
    expect(response.body).to include("href=\"#{tags_path}\"")
  end

  it "shows published tagged items and lists to guests" do
    visible_item = list.listed_items.create!(designation: "Visible card", privacy: :published)
    hidden_item = list.listed_items.create!(designation: "Draft card", privacy: :draft)
    visible_item.taggings.create!(tag: commander, mage: owner)
    hidden_item.taggings.create!(tag: commander, mage: owner)
    list.taggings.create!(tag: commander, mage: owner)
    unreviewed_list = List.create!(name: "Unreviewed tagged list", mage: owner, privacy: :unreviewed)
    unreviewed_list.taggings.create!(tag: commander, mage: owner)

    get tag_path(commander)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Commander", "Visible card", "Published tagged list", "Unreviewed tagged list")
    expect(response.body).to include(list_path(list))
    expect(response.body).not_to include("Draft card")
  end

  it "hides unpublished tagged records from guests and shows them to the owner" do
    draft_list = List.create!(name: "Owner draft list", mage: owner, privacy: :draft)
    draft_item = draft_list.listed_items.create!(designation: "Owner draft item", privacy: :draft)
    draft_item.taggings.create!(tag: sleeper, mage: owner)
    draft_list.taggings.create!(tag: sleeper, mage: owner)

    get tag_path(sleeper)
    expect(response.body).not_to include("Owner draft item", "Owner draft list")

    sign_in owner
    get tag_path(sleeper)
    expect(response.body).to include("Owner draft item", "Owner draft list")
  end

  it "links applied chips on a list to the tag page" do
    list.taggings.create!(tag: commander, mage: owner)

    get list_path(list)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(tag_path(commander))
  end
end
