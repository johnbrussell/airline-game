class AirportsController < ApplicationController
  def index
    @game = params[:game_id]
    @airports = Airport.all
  end
end
