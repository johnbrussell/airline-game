class RivalCountryGroup < ApplicationRecord
  validates :country_one, presence: true
  validates :country_two, presence: true

  validate :countries_alphabetized

  def self.rivals?(country_group_1, country_group_2)
    find_by(country_one: country_group_1, country_two: country_group_2).present? ||
      find_by(country_one: country_group_2, country_two: country_group_1).present?
  end

  private

    def countries_alphabetized
      if country_one >= country_two
        errors.add(:country_groups, "must be alphabetized")
      end
    end
end
