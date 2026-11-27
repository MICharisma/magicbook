class Ahoy::Visit < ApplicationRecord
  self.table_name = "ahoy_visits"

  has_many :events, class_name: "Ahoy::Event", dependent: :destroy
  belongs_to :user, class_name: "Mage", optional: true
end
