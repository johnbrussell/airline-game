Fabricator(:market) do
  name { ["Boston", "New York", "London", "Nauru"].sample }
  country { ["United States", "United Kingdom", "Nauru"].sample }
  country_group { ["United States", "United Kingdom", "Nauru"].sample }
  income { [1000, 10000, 50000, 100000].sample }
  latitude { sequence(:latitude, Random.rand(0..89)) { |lat| (lat % 179) - 89 } }
  longitude { sequence(:longitude, Random.rand(0..179)) { |long| (long % 359) - 179 } }
end
