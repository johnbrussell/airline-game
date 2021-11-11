class Market < ApplicationRecord
  validates :name, presence: true
  validates :country, presence: true
  validates :income, presence: true
  validates :income, numericality: { greater_than: 0 }
  validates :is_national_capital, :inclusion => { :in => [true, false] }
  validates :is_island, :inclusion => { :in => [true, false] }

  validates_uniqueness_of :name

  has_many :populations
  has_many :tourists, class_name: "Tourists"
  has_many :airports
  has_many :global_demands

  def shared_catchment
    100 - airports.map(&:exclusive_catchment).sum
  end
end
