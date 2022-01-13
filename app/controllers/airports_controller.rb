class AirportsController < ApplicationController
  def index
    @game = params[:game_id]
  end
end
