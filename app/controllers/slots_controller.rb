class SlotsController < ApplicationController
  def index
    @game = Game.find(params[:game_id])
    @airline = Airline.find(params[:airline_id])
  end
end
