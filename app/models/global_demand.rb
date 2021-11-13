class GlobalDemand < ApplicationRecord
  validates :business, numericality: { greater_than_or_equal_to: 0 }
  validates :business, presence: true
  validates :government, numericality: { greater_than_or_equal_to: 0 }
  validates :government, presence: true
  validates :leisure, numericality: { greater_than_or_equal_to: 0 }
  validates :leisure, presence: true
  validates :tourist, numericality: { greater_than_or_equal_to: 0 }
  validates :tourist, presence: true
end
