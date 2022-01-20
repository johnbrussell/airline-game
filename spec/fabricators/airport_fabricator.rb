Fabricator(:airport) do
  iata { ["BOS", "LGA", "JFK", "LHR", "LGW", "INU"].sample }
  exclusive_catchment { [0, 1, 10].sample }
  runway 5000
  elevation 100
  start_gates { Random.rand(1..5) }
  easy_gates 5
  latitude { Random.rand(-89..90) }
  longitude { Random.rand(-180..179) }
  market
end
