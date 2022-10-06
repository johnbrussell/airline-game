Fabricator(:airport) do
  iata { ["BOS", "LGA", "JFK", "LHR", "LGW", "INU"].sample }
  exclusive_catchment { [1, 10, 100].sample }
  runway 5000
  elevation 100
  start_gates { Random.rand(1..5) }
  easy_gates 5
  latitude { Random.rand(-89..89) }
  longitude { Random.rand(-179..179) }
  municipality { [nil, "Gary"].sample }
  market
end
