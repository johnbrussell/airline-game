class Game < ApplicationRecord
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :current_date, presence: true
end
