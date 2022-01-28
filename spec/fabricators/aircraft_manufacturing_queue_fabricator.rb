Fabricator(:aircraft_manufacturing_queue) do
  production_rate { [1, 2, 3, 4, 5].sample }
  aircraft_family_id { Fabricate(:aircraft_family).id }
  game_id { Fabricate(:game).id }
end
