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

  context "initialization" do
    it "initializes successfully with no opts" do
      subject = TestClass.new(airport1, airport2, Date.today)

      expect(subject.instance_variable_get(:@flight_distance)).to be nil
      expect(Calculation::Distance).to receive(:between_airports).with(airport1, airport2).and_return 100

      expect(subject.send(:flight_distance)).to eq 100
      expect(subject.instance_variable_get(:@flight_distance)).to eq 100
    end

    it "sets any opts as instance variables" do
      subject = TestClass.new(airport1, airport2, Date.today, foo: 10, bar: 100, flight_distance: 200)

      expect(subject.instance_variable_get(:@foo)).to eq 10
      expect(subject.instance_variable_get(:@bar)).to eq 100
      expect(subject.instance_variable_get(:@flight_distance)).to eq 200

      expect(Calculation::Distance).not_to receive(:new)

      expect(subject.send(:flight_distance)).to eq 200
      expect(subject.instance_variable_get(:@flight_distance)).to eq 200
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
