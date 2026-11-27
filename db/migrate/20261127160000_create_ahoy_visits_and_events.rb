class CreateAhoyVisitsAndEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :ahoy_visits, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :visit_token
      t.string :visitor_token
      t.references :user, type: :uuid, foreign_key: { to_table: :mages, on_delete: :nullify }
      t.string :ip
      t.text :user_agent
      t.text :referrer
      t.string :referring_domain
      t.text :landing_page
      t.string :browser
      t.string :os
      t.string :device_type
      t.string :country
      t.string :region
      t.string :city
      t.float :latitude
      t.float :longitude
      t.string :utm_source
      t.string :utm_medium
      t.string :utm_term
      t.string :utm_content
      t.string :utm_campaign
      t.string :app_version
      t.string :os_version
      t.string :platform
      t.datetime :started_at

      t.index :visit_token, unique: true
      t.index [ :visitor_token, :started_at ]
    end

    create_table :ahoy_events, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :visit, type: :uuid, null: false, foreign_key: { to_table: :ahoy_visits, on_delete: :cascade }
      t.references :user, type: :uuid, foreign_key: { to_table: :mages, on_delete: :nullify }
      t.string :name, null: false
      t.jsonb :properties, null: false, default: {}
      t.datetime :time, null: false

      t.index [ :name, :time ]
      t.index :properties, using: :gin, opclass: :jsonb_path_ops
    end
  end
end
