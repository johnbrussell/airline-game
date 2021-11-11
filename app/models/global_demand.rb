class GlobalDemand < ApplicationRecord
  validates :business, numericality: { greater_than_or_equal_to: 0 }
  validates :leisure, numericality: { greater_than_or_equal_to: 0 }

  OUT_OF_DATE_DISTANCE_DAYS = 182.days

  def out_of_date_from?(test_date)
    (date - test_date).abs().days > OUT_OF_DATE_DISTANCE_DAYS
  end
end
