class AirportsController < ApplicationController
  def build_gate
    @game = Game.find(params[:game_id])
    @airport = Airport.find(params[:airport_id])
    @gates = Gates.at_airport(@airport, @game)
    @gates.build_new_gate(@game.user_airline, @game.current_date)
    render :show
  end

  def lease_slot
    @game = Game.find(params[:game_id])
    @airport = Airport.find(params[:airport_id])
    @gates = Gates.at_airport(@airport, @game)
    @gates.lease_a_slot(@game.user_airline)
    render :show
  end

  def index
    @game = Game.find(params[:game_id])
    @airports = Airport.select_options
  end

  def select_airport
    redirect_to game_airport_path(params[:game_id], params[:id])
  end

  def show
    @game = Game.find(params[:game_id])
    @airport = Airport.find(params[:id] || params[:airport_id])
    @gates = Gates.at_airport(@airport, @game)
  end
end
