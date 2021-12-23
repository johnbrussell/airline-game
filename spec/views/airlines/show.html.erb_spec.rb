require "rails_helper"

RSpec.describe "airlines/index", type: :view do
  before(:each) do
    game = Game.create!(
      start_date: Date.today,
      end_date: Date.tomorrow,
      current_date: Date.tomorrow,
    )
    Airline.create!(
      game_id: game.id,
      name: "A Air",
      cash_on_hand: 100,
    )
    Airline.create!(
      game_id: game.id,
      name: "B Air",
      cash_on_hand: 100,
    )
  end

  context "index" do
    it "shows the name of each airline" do
      game = Game.last

      render :template => "airlines/index.html.erb", :locals => { :@airlines => Airline.all }

      expect(rendered).to include(Airline.first.name)
      expect(rendered).to include(Airline.last.name)
    end
  end
end
