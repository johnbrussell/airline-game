class SlotsController < ApplicationController
  def index
    @game = Game.find(params[:game_id])
    @airline = Airline.find(params[:airline_id])
    @airports = Airport.with_slots(@airline)
  end
end
