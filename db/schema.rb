# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_10_17_183326) do

  create_table "aircraft_families", force: :cascade do |t|
    t.string "name", null: false
    t.string "manufacturer", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "country_group", null: false
  end

  create_table "aircraft_manufacturing_queues", force: :cascade do |t|
    t.integer "game_id"
    t.integer "aircraft_family_id"
    t.float "production_rate"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["aircraft_family_id"], name: "index_aircraft_manufacturing_queues_on_aircraft_family_id"
    t.index ["game_id"], name: "index_aircraft_manufacturing_queues_on_game_id"
  end

  create_table "aircraft_models", force: :cascade do |t|
    t.string "name", null: false
    t.integer "production_start_year", null: false
    t.integer "floor_space", null: false
    t.integer "max_range", null: false
    t.integer "fuel_burn", null: false
    t.integer "speed", null: false
    t.integer "num_pilots", null: false
    t.integer "num_flight_attendants", null: false
    t.integer "price", null: false
    t.integer "takeoff_distance", null: false
    t.integer "useful_life", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "aircraft_family_id"
    t.integer "num_aisles", default: 1, null: false
    t.index ["aircraft_family_id"], name: "index_aircraft_models_on_aircraft_family_id"
  end

  create_table "airline_route_revenues", force: :cascade do |t|
    t.integer "airline_route_id"
    t.float "revenue", null: false
    t.float "economy_pax", null: false
    t.float "premium_economy_pax", null: false
    t.float "business_pax", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.float "exclusive_economy_revenue", null: false
    t.float "exclusive_premium_economy_revenue", null: false
    t.float "exclusive_business_revenue", null: false
    t.index ["airline_route_id"], name: "index_airline_route_revenues_on_airline_route_id"
  end

  create_table "airline_routes", force: :cascade do |t|
    t.float "economy_price", null: false
    t.float "premium_economy_price", null: false
    t.float "business_price", null: false
    t.string "origin_airport_id", null: false
    t.string "destination_airport_id", null: false
    t.integer "distance", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "airline_id", null: false
    t.integer "service_quality", default: 1, null: false
  end

  create_table "airlines", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "is_user_airline", default: false, null: false
    t.integer "game_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.float "cash_on_hand", null: false
    t.integer "base_id", null: false
    t.index ["game_id"], name: "index_airlines_on_game_id"
  end

  create_table "airplane_routes", force: :cascade do |t|
    t.integer "airline_route_id"
    t.integer "airplane_id"
    t.integer "frequencies", null: false
    t.integer "block_time_mins", null: false
    t.float "flight_cost", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["airline_route_id"], name: "index_airplane_routes_on_airline_route_id"
    t.index ["airplane_id"], name: "index_airplane_routes_on_airplane_id"
  end

  create_table "airplanes", force: :cascade do |t|
    t.integer "aircraft_model_id"
    t.integer "business_seats", default: 0, null: false
    t.integer "premium_economy_seats", default: 0, null: false
    t.integer "economy_seats", default: 0, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.date "construction_date", null: false
    t.integer "aircraft_manufacturing_queue_id"
    t.integer "operator_id"
    t.integer "owner_id"
    t.date "lease_expiry"
    t.date "end_of_useful_life", null: false
    t.float "lease_rate"
    t.string "base_country_group", null: false
    t.index ["aircraft_manufacturing_queue_id"], name: "index_airplanes_on_aircraft_manufacturing_queue_id"
    t.index ["aircraft_model_id"], name: "index_airplanes_on_aircraft_model_id"
  end

  create_table "airport_populations", force: :cascade do |t|
    t.integer "airport_id"
    t.integer "year", null: false
    t.float "government", null: false
    t.float "population", null: false
    t.float "tourists", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["airport_id"], name: "index_airport_populations_on_airport_id"
  end

  create_table "airports", force: :cascade do |t|
    t.integer "market_id"
    t.string "iata", null: false
    t.float "exclusive_catchment", default: 100.0, null: false
    t.integer "runway", null: false
    t.integer "elevation", null: false
    t.integer "start_gates", null: false
    t.integer "easy_gates", null: false
    t.float "latitude", null: false
    t.float "longitude", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "municipality"
    t.index ["iata"], name: "index_airports_on_iata", unique: true
    t.index ["market_id"], name: "index_airports_on_market_id"
  end

  create_table "cabotage_exceptions", force: :cascade do |t|
    t.string "country", null: false
    t.string "excepted_country_group"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "frequency_tiers", force: :cascade do |t|
    t.integer "airline_route_id"
    t.integer "seats", null: false
    t.float "passengers", null: false
    t.string "class_of_service", null: false
    t.float "reputation"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["airline_route_id"], name: "index_frequency_tiers_on_airline_route_id"
  end

  create_table "games", force: :cascade do |t|
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.date "current_date", null: false
  end

  create_table "gates", force: :cascade do |t|
    t.integer "airport_id"
    t.integer "game_id"
    t.integer "current_gates", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["airport_id"], name: "index_gates_on_airport_id"
    t.index ["game_id"], name: "index_gates_on_game_id"
  end

  create_table "global_demands", force: :cascade do |t|
    t.integer "business", limit: 8, null: false
    t.integer "leisure", limit: 8, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "tourist", limit: 8, null: false
    t.integer "government", limit: 8, null: false
    t.integer "airport_id"
    t.integer "year", null: false
    t.index ["airport_id"], name: "index_global_demands_on_airport_id"
  end

  create_table "island_exceptions", force: :cascade do |t|
    t.string "market_one"
    t.string "market_two"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "market_dollars", force: :cascade do |t|
    t.integer "market_id"
    t.integer "year"
    t.integer "business", limit: 8, null: false
    t.integer "government", limit: 8, null: false
    t.integer "leisure", limit: 8, null: false
    t.integer "tourist", limit: 8, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["market_id", "year"], name: "index_market_dollars_on_market_and_year", unique: true
    t.index ["market_id"], name: "index_market_dollars_on_market_id"
    t.index ["year"], name: "index_market_dollars_on_year"
  end

  create_table "market_populations", force: :cascade do |t|
    t.integer "market_id"
    t.integer "year", null: false
    t.float "government", null: false
    t.float "population", null: false
    t.float "tourists", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["market_id"], name: "index_market_populations_on_market_id"
  end

  create_table "markets", force: :cascade do |t|
    t.string "name", null: false
    t.string "country", null: false
    t.integer "income", null: false
    t.boolean "is_national_capital", default: false, null: false
    t.boolean "is_island", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "country_group", null: false
    t.string "territory_of"
    t.float "latitude", null: false
    t.float "longitude", null: false
    t.index ["name"], name: "index_markets_on_name", unique: true
  end

  create_table "populations", force: :cascade do |t|
    t.integer "market_id"
    t.integer "population", null: false
    t.integer "year", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["market_id"], name: "index_populations_on_market_id"
    t.index ["year"], name: "index_populations_on_year"
  end

  create_table "relative_demands", force: :cascade do |t|
    t.integer "origin_market_id", null: false
    t.integer "destination_market_id", null: false
    t.string "origin_airport_iata", default: "", null: false
    t.string "destination_airport_iata", default: "", null: false
    t.float "business", null: false
    t.float "government", null: false
    t.float "leisure", null: false
    t.float "tourist", null: false
    t.float "pct_economy", null: false
    t.float "pct_premium_economy", null: false
    t.float "pct_business", null: false
    t.date "last_measured", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["origin_market_id", "destination_market_id", "origin_airport_iata", "destination_airport_iata", "last_measured"], name: "index_relative_demand_for_uniqueness_between_airports", unique: true
  end

  create_table "rival_country_groups", force: :cascade do |t|
    t.string "country_one", null: false
    t.string "country_two", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "route_demands", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.float "business", null: false
    t.string "destination_iata", null: false
    t.float "government", null: false
    t.float "leisure", null: false
    t.string "origin_iata", null: false
    t.float "tourist", null: false
    t.integer "year", null: false
    t.float "exclusive_business", null: false
    t.float "exclusive_government", null: false
    t.float "exclusive_leisure", null: false
    t.float "exclusive_tourist", null: false
  end

  create_table "route_dollars", force: :cascade do |t|
    t.integer "origin_market_id", null: false
    t.integer "destination_market_id", null: false
    t.string "origin_airport_iata", null: false
    t.string "destination_airport_iata", null: false
    t.date "date", null: false
    t.float "economy", null: false
    t.float "premium_economy", null: false
    t.float "business", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["origin_market_id", "destination_market_id", "origin_airport_iata", "destination_airport_iata", "date"], name: "index_route_dollars_for_uniqueness_between_airports", unique: true
  end

  create_table "slots", force: :cascade do |t|
    t.integer "lessee_id"
    t.date "lease_expiry"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "gates_id"
    t.float "rent", default: 0.0, null: false
    t.index ["gates_id"], name: "index_slots_on_gates_id"
  end

  create_table "total_market_demands", force: :cascade do |t|
    t.integer "market_id"
    t.integer "year", null: false
    t.integer "business", limit: 8, null: false
    t.integer "government", limit: 8, null: false
    t.integer "leisure", limit: 8, null: false
    t.integer "tourist", limit: 8, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["market_id", "year"], name: "index_total_market_demand_on_market_and_year", unique: true
    t.index ["market_id"], name: "index_total_market_demands_on_market_id"
  end

  create_table "tourists", force: :cascade do |t|
    t.integer "market_id"
    t.integer "volume", null: false
    t.integer "year", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["market_id"], name: "index_tourists_on_market_id"
    t.index ["year"], name: "index_tourists_on_year"
  end

end
