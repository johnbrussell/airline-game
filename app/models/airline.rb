class Airline < ApplicationRecord
  validates :cash_on_hand, presence: true
  validates :name, presence: true
  validates :is_user_airline, :inclusion => { :in => [true, false] }
end
