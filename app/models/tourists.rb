class Tourists < ApplicationRecord
  validates :volume, presence: true
  validates :volume, numericality: { greater_than_or_equal_to: 0 }
  validates :year, presence: true
  validates :year, numericality: { greater_than_or_equal_to: 1914 }
end
