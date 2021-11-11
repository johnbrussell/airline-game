class Population < ApplicationRecord
  validates :population, presence: true
  validates :population, numericality: { greater_than_or_equal_to: 0 }  # 0 okay because maybe some places are founded after 1914
  validates :year, presence: true
  validates :year, numericality: { greater_than_or_equal_to: 1914 }
end
