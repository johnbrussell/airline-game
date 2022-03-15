class SlotsController < ApplicationController
  def index
    @game = Game.find(params[:game_id])
    @airline = Airline.find(params[:airline_id])
    @airports = Airport.with_slots(@airline)
  end

  def return
    @game = Game.find(params[:game_id])
    @airline = Airline.find(params[:airline_id])
    airport = Airport.find(params[:airport_id])
    Gates.at_airport(airport, @game).return_a_slot(@airline)
    @airports = Airport.with_slots(@airline)
    render :index
  end
end
