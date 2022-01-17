Fabricator(:airline) do
  cash_on_hand { [1000, 1000000, 100000000, 10000000000].sample }
  name { ["A Air", "B Air", "C Air"].sample }
  is_user_airline false
  base_id { Fabricate(:market).id }
  game_id { Fabricate(:game).id }
end
