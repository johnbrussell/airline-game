class AirlinesController < ApplicationController
  def index
    @airlines = Airline.all
  end
end
