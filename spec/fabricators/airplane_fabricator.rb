Fabricator(:airplane) do
  transient :aircraft_family

  base_country_group { ["United States", "Europe", "Russia"].sample }
  construction_date Date.yesterday
  end_of_useful_life Date.tomorrow
  aircraft_manufacturing_queue { |attrs| Fabricate(:aircraft_manufacturing_queue, aircraft_family_id: attrs[:aircraft_family].id) }
  operator_id nil
  aircraft_model { |attrs| Fabricate(:aircraft_model, family: attrs[:aircraft_family]) }
end
