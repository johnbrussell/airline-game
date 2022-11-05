Fabricator(:market) do
  name { ["Boston", "New York", "London", "Nauru"].sample }
  country { ["United States", "United Kingdom", "Nauru"].sample }
  country_group { ["United States", "United Kingdom", "Nauru"].sample }
  income { [1000, 10000, 50000, 100000].sample }
end
