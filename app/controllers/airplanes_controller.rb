class AirplanesController < ApplicationController
  def index
    @game = Game.find(params[:game_id])
    @airline = Airline.find(params[:airline_id])
    @built_airplanes = Airplane.
      with_operator(@airline.id).
      where("construction_date <= ?", @game.current_date).
      neatly_sorted
    @unbuilt_airplanes = Airplane.
      with_operator(@airline.id).
      where("construction_date > ?", @game.current_date).
      neatly_sorted
  end

  def lease
    @game = Game.find(params[:game_id])
    @airplane = Airplane.find(params[:airplane_id])
    country = @airplane.base_country_group
    days = params[:airplane][:days].to_i
    business_seats = if @airplane.built? then nil else params[:airplane][:business_seats] end
    premium_economy_seats = if @airplane.built? then nil else params[:airplane][:premium_economy_seats] end
    economy_seats = if @airplane.built? then nil else params[:airplane][:economy_seats] end
    if @airplane.lease(@game.user_airline, days, business_seats, premium_economy_seats, economy_seats)
      redirect_to game_airline_airplanes_path(@game, @game.user_airline)
    else
      @airplane.assign_attributes(base_country_group: country)
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
    country = @airplane.base_country_group
    business_seats = if @airplane.built? then nil else params[:airplane][:business_seats] end
    premium_economy_seats = if @airplane.built? then nil else params[:airplane][:premium_economy_seats] end
    economy_seats = if @airplane.built? then nil else params[:airplane][:economy_seats] end
    if @airplane.purchase(@game.user_airline, business_seats, premium_economy_seats, economy_seats)
      redirect_to game_airline_airplanes_path(@game, @game.user_airline)
    else
      @airplane.assign_attributes(base_country_group: country)
      render :purchase_information
    end
  end

  def purchase_information
    @game = Game.find(params[:game_id])
    @airplane = Airplane.find(params[:airplane_id])
  end

  def show
    @game = Game.find(params[:game_id])
    @airline = Airline.find(params[:airline_id])
    @airplane = Airplane.find(params[:id])
  end
end
