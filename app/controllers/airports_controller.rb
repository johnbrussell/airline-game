class AirportsController < ApplicationController
  def index
    @game = Game.find(params[:game_id])
    @airports = Airport.select_options
  end

  def select_airport
    redirect_to game_airport_path(params[:game_id], params[:id])
  end

  def show
    @game = Game.find(params[:game_id])
    @airport = Airport.find(params[:id])
    @gates = Gates.at_airport(@airport, @game)
  end
end
