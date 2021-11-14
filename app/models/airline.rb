class Airline < ApplicationRecord
  validates :name, presence: true
  validates :is_user_airline, :inclusion => { :in => [true, false] }
end
