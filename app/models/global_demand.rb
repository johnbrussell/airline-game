class GlobalDemand < ApplicationRecord
  validates :business, numericality: { greater_than_or_equal_to: 0 }
  validates :leisure, numericality: { greater_than_or_equal_to: 0 }
end
