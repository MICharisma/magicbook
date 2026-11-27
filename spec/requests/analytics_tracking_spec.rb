require "rails_helper"

RSpec.describe "Analytics tracking", type: :request do
  before do
    host! "localhost"
    create_featured_book!
  end

  it "records an anonymous visit with masked IP and app-analytics metadata" do
    get root_path, headers: { "REMOTE_ADDR" => "203.0.113.42" }

    expect(response).to have_http_status(:ok)
    visit = Ahoy::Visit.sole
    expect(visit.user).to be_nil
    expect(visit.ip).to eq("203.0.113.0")
    expect(cookies["ahoy_visit"]).to eq(visit.visit_token)
    expect(cookies["ahoy_visitor"]).to eq(visit.visitor_token)

    context = JSON.parse(Nokogiri::HTML(response.body).at_css('meta[name="app-analytics"]')["content"])
    expect(context).to include("page_type" => "landings.home", "path" => "/", "signed_in" => false, "enabled" => true)
  end

  it "accepts browser events on the active visit without minting orphan visits" do
    get root_path
    visit = Ahoy::Visit.sole
    context = JSON.parse(Nokogiri::HTML(response.body).at_css('meta[name="app-analytics"]')["content"])

    post "/ahoy/events",
         params: {
           visit_token: cookies["ahoy_visit"],
           visitor_token: cookies["ahoy_visitor"],
           events: [ { name: "page_viewed", properties: context.except("enabled") } ]
         },
         as: :json

    expect(response).to have_http_status(:ok)
    expect(Ahoy::Visit.count).to eq(1)
    expect(Ahoy::Event.where(name: "page_viewed").sole.visit).to eq(visit)
  end

  it "links an anonymous browsing visit on Devise sign-in and nullifies user_id when deleted" do
    mage = Mage.create!(email: "reader@example.test", password: "password123", password_confirmation: "password123", confirmed_at: Time.current)
    get root_path
    visit = Ahoy::Visit.sole

    post mage_session_path, params: { mage: { email: mage.email, password: "password123" } }
    expect(visit.reload.user).to eq(mage)
    expect(Ahoy::Visit.count).to eq(1)

    mage.destroy!
    expect(visit.reload.user_id).to be_nil
  end

  it "scrubs magic-link tokens in analytics paths" do
    get consume_magic_link_path(token: "secret-magic-token")
    expect(controller.send(:analytics_context)[:path]).to eq("/magic-link/:token")
  end

  it "excludes admin mages and opt-out cookies from visits and events" do
    admin = Mage.create!(email: "admin@example.test", password: "password123", password_confirmation: "password123", confirmed_at: Time.current, admin: true)
    sign_in admin
    get root_path
    expect(JSON.parse(Nokogiri::HTML(response.body).at_css('meta[name="app-analytics"]')["content"])["enabled"]).to be(false)

    post "/ahoy/events",
         params: { visit_token: SecureRandom.uuid, visitor_token: SecureRandom.uuid, events: [ { name: "page_viewed", properties: {} } ] },
         as: :json
    expect(response).to have_http_status(:ok)
    expect(Ahoy::Visit.count).to eq(0)
    expect(Ahoy::Event.count).to eq(0)

    sign_out admin
    cookies[:magicbook_analytics_exclude] = "1"
    get root_path
    expect(Ahoy::Visit.count).to eq(0)
  end
end
