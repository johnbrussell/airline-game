class RivalCountryGroup < ApplicationRecord
  validates :country_one, presence: true
  validates :country_two, presence: true

  validate :countries_alphabetized

  private

    def countries_alphabetized
      if country_one >= country_two
        errors.add(:country_groups, "must be alphabetized")
      end
    end
end
