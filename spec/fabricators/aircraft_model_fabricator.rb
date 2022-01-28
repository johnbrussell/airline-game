Fabricator(:aircraft_model) do
  name { ["A318", "A319", "A320", "A321", "737-600", "737-700", "737-800", "737-900"].sample }
  production_start_year { 1930 }
  floor_space { 10000 }
  max_range { 2500 }
  speed { 500 }
  fuel_burn { 1500 }
  num_pilots { 2 }
  num_flight_attendants { 3 }
  price { 100000000 }
  takeoff_distance { 9000 }
  useful_life { 30 }
  family { Fabricate(:aircraft_family) }
end
