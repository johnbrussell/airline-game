class Tourists < ApplicationRecord
  validates :volume, presence: true
  validates :year, presence: true
end
