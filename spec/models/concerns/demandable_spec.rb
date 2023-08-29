require "rails_helper"

RSpec.describe Demandable do
  airport1 = Airport.new(market: Market.new(country: "United States"))
  airport2 = Airport.new(market: Market.new(country: "United States"))
  airport3 = Airport.new(market: Market.new(country: "Canada", country_group: "Empire of Canada"))
  airport4 = Airport.new(market: Market.new(country: "Not Canada", country_group: "Empire of Canada"))

  context "domestic?" do
    it "is true when the airports are in the same country" do
      subject = TestClass.new(airport1, airport2, Date.today)

      expect(subject.send(:domestic?)).to be true
    end

    it "is false when the airports are in different countries" do
      subject = TestClass.new(airport1, airport3, Date.today)

      expect(subject.send(:domestic?)).to be false
    end
  end

  context "same_country_group?" do
    it "is true when the airports are in the same country group" do
      subject = TestClass.new(airport3, airport4, Date.today)

      expect(subject.send(:domestic?)).to be false
      expect(subject.send(:same_country_group?)).to be true
    end

    it "is false when the airports are in different country groups" do
      subject = TestClass.new(airport1, airport3, Date.today)

      expect(subject.send(:domestic?)).to be false
      expect(subject.send(:same_country_group?)).to be false
    end
  end
end

class TestClass
  include Demandable
end
