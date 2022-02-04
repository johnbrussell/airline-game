Fabricator(:aircraft_family) do
  country_group { ["United States", "Russia", "Europe"].sample }
  manufacturer { ["Airbus", "Boeing"].sample }
  name { ["A320", "737"].sample }
end
