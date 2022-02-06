require "rails_helper"

RSpec.describe RivalCountryGroup do
  context "rivals?" do
    it "calculates correctly" do
      RivalCountryGroup.create!(country_one: "Nauru", country_two: "Tuvalu")

      expect(RivalCountryGroup.rivals?("Nauru", "Tuvalu")).to be true
      expect(RivalCountryGroup.rivals?("Tuvalu", "Nauru")).to be true
      expect(RivalCountryGroup.rivals?("Tuvalu", "United States")).to be false
      expect(RivalCountryGroup.rivals?("Nauru", "United States")).to be false
      expect(RivalCountryGroup.rivals?("United States", "Nauru")).to be false
      expect(RivalCountryGroup.rivals?("United States", "Tuvalu")).to be false
    end
  end

  context "valid?" do
    it "is true when the country groups are alphabetized" do
      subject = RivalCountryGroup.create(country_one: "Marshall Islands", country_two: "Micronesia")

      expect(subject.valid?).to be true
    end

    it "is false when the country groups are equal" do
      subject = RivalCountryGroup.create(country_one: "United States", country_two: "United States")

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Country groups must be alphabetized"
    end

    it "is false when the country groups are not alphabetized" do
      subject = RivalCountryGroup.create(country_one: "United States", country_two: "United Arab Emirates")

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Country groups must be alphabetized"
    end
  end
end
