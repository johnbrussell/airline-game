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

ActiveRecord::Schema.define(version: 2021_11_14_214030) do

  create_table "airlines", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "is_user_airline", default: false, null: false
    t.integer "game_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["game_id"], name: "index_airlines_on_game_id"
  end

  create_table "airports", force: :cascade do |t|
    t.integer "market_id"
    t.string "iata", null: false
    t.float "exclusive_catchment", default: 0.0, null: false
    t.integer "runway", null: false
    t.integer "elevation", null: false
    t.integer "start_gates", null: false
    t.integer "easy_gates", null: false
    t.float "latitude", null: false
    t.float "longitude", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["iata"], name: "index_airports_on_iata", unique: true
    t.index ["market_id"], name: "index_airports_on_market_id"
  end

  create_table "games", force: :cascade do |t|
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.date "current_date", null: false
  end

  create_table "global_demands", force: :cascade do |t|
    t.date "date", null: false
    t.integer "business", limit: 8, null: false
    t.integer "leisure", limit: 8, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "tourist", limit: 8, null: false
    t.integer "government", limit: 8, null: false
    t.integer "airport_id"
    t.index ["airport_id"], name: "index_global_demands_on_airport_id"
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
    t.index ["name"], name: "index_markets_on_name", unique: true
  end

  create_table "populations", force: :cascade do |t|
    t.integer "market_id"
    t.integer "population", null: false
    t.integer "year", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["market_id"], name: "index_populations_on_market_id"
  end

  create_table "tourists", force: :cascade do |t|
    t.integer "market_id"
    t.integer "volume", null: false
    t.integer "year", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["market_id"], name: "index_tourists_on_market_id"
  end

end
