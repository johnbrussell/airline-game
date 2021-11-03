class Market < ApplicationRecord
  validates :name, presence: true
  validates :country, presence: true
  validates :income, presence: true
  validates :is_national_capital, presence: true
  validates :is_island, presence: true
end
