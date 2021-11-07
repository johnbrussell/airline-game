class Population < ApplicationRecord
  validates :population, presence: true
  validates :year, presence: true
end
