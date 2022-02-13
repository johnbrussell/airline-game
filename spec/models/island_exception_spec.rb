require "rails_helper"

RSpec.describe IslandException do
  context "excepted?" do
    it "is true if the exception exists" do
      IslandException.create!(market_one: "Nauru", market_two: "Funafuti")

      inu = Market.create!(name: "Nauru", income: 1, country: "Pacific", country_group: "Pacific")
      fun = Market.create!(name: "Funafuti", income: 1, country: "Pacific", country_group: "Pacific")

      expect(IslandException.excepted?(inu, fun)).to be true
      expect(IslandException.excepted?(fun, inu)).to be true
    end

    it "is false if the exception does not exist" do
      inu = Market.create!(name: "Nauru", income: 1, country: "Pacific", country_group: "Pacific")
      fun = Market.create!(name: "Funafuti", income: 1, country: "Pacific", country_group: "Pacific")

      expect(IslandException.excepted?(inu, fun)).to be false
      expect(IslandException.excepted?(fun, inu)).to be false

      IslandException.create!(market_one: "Nauru", market_two: "Majuro")

      expect(IslandException.excepted?(inu, fun)).to be false
      expect(IslandException.excepted?(fun, inu)).to be false

      IslandException.create!(market_one: "Funafuti", market_two: "Majuro")

      expect(IslandException.excepted?(inu, fun)).to be false
      expect(IslandException.excepted?(fun, inu)).to be false
    end
  end
end
