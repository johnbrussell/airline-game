class Market < ApplicationRecord
  validates :name, presence: true
  validates :country, presence: true
  validates :income, presence: true
  validates :income, numericality: { greater_than: 0 }
  validates :is_national_capital, :inclusion => { :in => [true, false] }
  validates :is_island, :inclusion => { :in => [true, false] }
  validates :business_demand, numericality: { greater_than_or_equal_to: 0 }
  validates :leisure_demand, numericality: { greater_than_or_equal_to: 0 }

  validates_uniqueness_of :name

  has_many :populations
  has_many :tourists, class_name: "Tourists"
  has_many :airports
  has_many :global_demands
end
