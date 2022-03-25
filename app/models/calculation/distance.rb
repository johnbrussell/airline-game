class Calculation::Distance
  EARTH_RADIUS = 3959

  def self.between_airports(airport1, airport2)
    self.haversine(airport1.latitude, airport1.longitude, airport2.latitude, airport2.longitude)
  end

  def self.between_markets(market1, market2)
    self.haversine(market1.latitude, market1.longitude, market2.latitude, market2.longitude)
  end

  private

    def self.haversine(lat1, long1, lat2, long2)
      origin_lat = self.to_radians_from_degrees(lat1)
      origin_long = self.to_radians_from_degrees(long1)
      dest_lat = self.to_radians_from_degrees(lat2)
      dest_long = self.to_radians_from_degrees(long2)

      delta_lat = (origin_lat - dest_lat) / 2
      delta_long = (origin_long - dest_long) / 2
      delta_lat = Math.sin(delta_lat) ** 2
      delta_long = Math.sin(delta_long) ** 2
      origin_lat = Math.cos(origin_lat)
      dest_lat = Math.cos(dest_lat)
      haversine = delta_lat + origin_lat * dest_lat * delta_long
      2 * 3959 * Math.asin(Math.sqrt(haversine))
    end

    def self.to_radians_from_degrees(degrees)
      degrees * Math::PI / 180
    end
end
