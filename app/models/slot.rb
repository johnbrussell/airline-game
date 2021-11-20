class Slot < ApplicationRecord
  validates :gates_id, presence: true
end
