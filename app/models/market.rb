class Market < ApplicationRecord
  validates :name, presence: true
  validates :country, presence: true
  validates :income, presence: true
  validates :is_national_capital, :inclusion => { :in => [true, false] }
  validates :is_island, :inclusion => { :in => [true, false] }

  validates_uniqueness_of :name

  has_many :populations
end
