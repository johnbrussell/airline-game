require "rails_helper"

RSpec.describe Gates do
  context "validate current_gates_greater_than_start_gates" do
    market = Market.create!(
      name: "City",
      country: "County",
      country_group: "Country",
      income: 1,
    )
    airport = Airport.create!(
      iata: "ABC",
      exclusive_catchment: 0,
      runway: 1000,
      elevation: 1000,
      start_gates: 2,
      easy_gates: 2,
      latitude: 40,
      longitude: 40,
      market: market,
    )
    game = Game.create!(
      start_date: Date.yesterday,
      end_date: Date.tomorrow,
      current_date: Date.today,
    )

    it "fails if current_gates is less than the airport's start_gates" do
      subject = Gates.new(airport: airport, game: game, current_gates: 1)

      assert_not subject.validate
      assert_includes(subject.errors.map{ |error| "#{error.attribute} #{error.message}" }, "current_gates cannot be less than minimum gates at airport")
    end

    it "passes if current_gates is equal to the airport's start_gates" do
      subject = Gates.new(airport: airport, game: game, current_gates: 2)

      assert subject.validate
    end

    it "passes if current_gates is greater than the airport's start_gates" do
      subject = Gates.new(airport: airport, game: game, current_gates: 3)

      assert subject.validate
    end
  end
end
