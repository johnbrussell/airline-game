class AirplanesController < ApplicationController
  def index
    @game = Game.find(params[:game_id])
    @airline = Airline.find(params[:airline_id])
    @airplanes = Airplane.
      with_operator(@airline.id).
      where("construction_date <= ?", @game.current_date).
      neatly_sorted
  end

  def lease
    @game = Game.find(params[:game_id])
    @airplane = Airplane.find(params[:airplane_id])
    days = params[:airplane][:days].to_i
    business_seats = params[:airplane][:business_seats]
    premium_economy_seats = params[:airplane][:premium_economy_seats]
    economy_seats = params[:airplane][:economy_seats]
    if @airplane.lease_new(@game.user_airline, days, business_seats, premium_economy_seats, economy_seats)
      redirect_to game_airline_airplanes_path(@game, @game.user_airline)
    else
      render :lease_information
    end
  end

  def lease_information
    @game = Game.find(params[:game_id])
    @airplane = Airplane.find(params[:airplane_id])
  end

  def purchase
    @game = Game.find(params[:game_id])
    @airplane = Airplane.find(params[:airplane_id])
    business_seats = params[:airplane][:business_seats]
    premium_economy_seats = params[:airplane][:premium_economy_seats]
    economy_seats = params[:airplane][:economy_seats]
    if @airplane.purchase_new(@game.user_airline, business_seats, premium_economy_seats, economy_seats)
      redirect_to game_airline_airplanes_path(@game, @game.user_airline)
    else
      render :purchase_information
    end
  end

  def purchase_information
    @game = Game.find(params[:game_id])
    @airplane = Airplane.find(params[:airplane_id])
  end
end
