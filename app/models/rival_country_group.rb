class RivalCountryGroup < ApplicationRecord
  validates :country_one, presence: true
  validates :country_two, presence: true
end
