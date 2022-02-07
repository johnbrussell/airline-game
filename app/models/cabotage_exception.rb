class CabotageException < ApplicationRecord
  validates :country, presence: true
end
