class RivalCountryGroup < ApplicationRecord
  validates :country_one, presence: true
  validates :country_two, presence: true

  validate :countries_alphabetized

  def self.all_rivals(country_group)
    RivalCountryGroup.where(country_one: country_group).or(where(country_two: country_group)).map do |r|
      [r.country_one, r.country_two].reject { |cg| cg == country_group }
    end.flatten
  end

  def self.rivals?(country_group_1, country_group_2)
    if country_group_1 == country_group_2
      false
    else
      find_by(country_one: country_group_1, country_two: country_group_2).present? ||
        find_by(country_one: country_group_2, country_two: country_group_1).present?
    end
  end

  private

    def countries_alphabetized
      if country_one >= country_two
        errors.add(:country_groups, "must be alphabetized")
      end
    end
end
