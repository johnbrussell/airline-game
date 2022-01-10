require "rails_helper"

RSpec.describe Airline do
  context "only_one_user_airline_exists" do
    it "is true when creating a non-user airline and no user airline exists" do
      Airline.create!(cash_on_hand: 1, name: "foo", is_user_airline: false, base_id: 1, game_id: 1)
      Airline.create!(cash_on_hand: 1, name: "bar", is_user_airline: false, base_id: 1, game_id: 1)

      expect(Airline.count).to eq 2
    end

    it "is true when creating a non-user airline and a user airline exists" do
      Airline.create!(cash_on_hand: 1, name: "foo", is_user_airline: true, base_id: 1, game_id: 1)
      Airline.create!(cash_on_hand: 1, name: "bar", is_user_airline: false, base_id: 1, game_id: 1)

      expect(Airline.count).to eq 2
    end

    it "is true when creating the only user airline" do
      Airline.create!(cash_on_hand: 1, name: "foo", is_user_airline: false, base_id: 1, game_id: 1)
      Airline.create!(cash_on_hand: 1, name: "bar", is_user_airline: true, base_id: 1, game_id: 1)

      expect(Airline.count).to eq 2
    end

    it "is true when creating an airline and a user airline exists in another game" do
      game = Game.create!(start_date: Date.yesterday, end_date: Date.tomorrow, current_date: Date.today)
      Airline.create!(cash_on_hand: 1, name: "foo", is_user_airline: true, game_id: game.id, base_id: 1)

      new_game = Game.create!(start_date: Date.yesterday, end_date: Date.tomorrow, current_date: Date.today)
      new_airline = Airline.new(cash_on_hand: 1, name: "bar", is_user_airline: true, game_id: new_game.id, base_id: 1)

      expect(new_airline.valid?).to be true
      expect(new_airline.save).to be true
      expect(Airline.count).to eq 2
    end

    it "is true when updating an airline" do
      airline = Airline.create!(cash_on_hand: 1, name: "foo", is_user_airline: true, base_id: 1, game_id: 1)

      expect(airline.update(name: "bar")).to eq true
    end

    it "is false when creating an airline and a user airline exists in the game" do
      game = Game.create!(start_date: Date.yesterday, end_date: Date.tomorrow, current_date: Date.today)
      Airline.create!(cash_on_hand: 1, name: "foo", is_user_airline: true, game_id: game.id, base_id: 1)

      new_airline = Airline.new(cash_on_hand: 1, name: "bar", is_user_airline: true, game_id: game.id, base_id: 1)

      expect(new_airline.valid?).to be false
      expect(new_airline.save).to be false
      expect(new_airline.errors.map{ |error| "#{error.attribute} #{error.message}" }).to include ("is_user_airline cannot be true for multiple airlines within a game")
    end
  end

  context "validate_a_user_airline_exists" do
    it "is false for a user airline" do
      airline = Airline.create!(cash_on_hand: 1, name: "foo", is_user_airline: true, base_id: 1, game_id: 1)

      expect(Airline.count).to eq 1
      airline.destroy
      expect(Airline.count).to eq 1
      expect(airline.errors.map{ |error| "#{error.attribute} #{error.message}" }).to include "is_user_airline must be true for at least one airline at all times"
    end

    it "is true for a non-user airline" do
      airline_1 = Airline.create!(cash_on_hand: 1, name: "foo", is_user_airline: false, base_id: 1, game_id: 1)
      airline_2 = Airline.create!(cash_on_hand: 1, name: "bar", is_user_airline: true, base_id: 1, game_id: 1)

      expect(Airline.count).to eq 2
      airline_1.destroy
      expect(Airline.count).to eq 1

      expect(Airline.last.id).to eq airline_2.id
    end
  end
end
