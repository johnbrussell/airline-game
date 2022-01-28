Fabricator(:aircraft_family) do
  manufacturer { ["Airbus", "Boeing"].sample }
  name { ["A320", "737"].sample }
end
