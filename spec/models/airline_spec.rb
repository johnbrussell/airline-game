require "rails_helper"

RSpec.describe Airline do
  context "only_one_user_airline_exists" do
    it "is true when creating a non-user airline and no user airline exists" do
      Airline.create!(cash_on_hand: 1, name: "foo", is_user_airline: false)
      Airline.create!(cash_on_hand: 1, name: "bar", is_user_airline: false)

      expect(Airline.count).to eq 2
    end

    it "is true when creating a non-user airline and a user airline exists" do
      Airline.create!(cash_on_hand: 1, name: "foo", is_user_airline: true)
      Airline.create!(cash_on_hand: 1, name: "bar", is_user_airline: false)

      expect(Airline.count).to eq 2
    end

    it "is true when creating the only user airline" do
      Airline.create!(cash_on_hand: 1, name: "foo", is_user_airline: false)
      Airline.create!(cash_on_hand: 1, name: "bar", is_user_airline: true)

      expect(Airline.count).to eq 2
    end

    it "is false when creating an airline and a user airline exists" do
      Airline.create!(cash_on_hand: 1, name: "foo", is_user_airline: true)

      new_airline = Airline.new(cash_on_hand: 1, name: "bar", is_user_airline: true)

      expect(new_airline.valid?).to be false
      expect(new_airline.save).to be false
      expect(new_airline.errors.map{ |error| "#{error.attribute} #{error.message}" }).to include ("is_user_airline cannot be true for multiple airlines")
    end
  end
end
