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

ActiveRecord::Schema.define(version: 2021_11_07_163830) do

  create_table "games", force: :cascade do |t|
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.date "current_date", null: false
  end

  create_table "markets", force: :cascade do |t|
    t.string "name", null: false
    t.string "country", null: false
    t.integer "income", null: false
    t.boolean "is_national_capital", default: false, null: false
    t.boolean "is_island", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
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

end
