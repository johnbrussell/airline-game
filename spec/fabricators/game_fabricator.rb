Fabricator(:game) do
  start_date Date.yesterday
  end_date Date.tomorrow
  current_date Date.today
end
