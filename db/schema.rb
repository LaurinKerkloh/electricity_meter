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

ActiveRecord::Schema[8.1].define(version: 2024_10_25_073040) do
  create_table "electricity_meter_readings", force: :cascade do |t|
    t.datetime "time", null: false
    t.decimal "reading", precision: 10, scale: 4
    t.integer "current_power"
    t.string "meter", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["time", "meter"], name: "index_electricity_meter_readings_on_time_and_meter", unique: true
  end

  create_table "trigger_points", force: :cascade do |t|
    t.string "direction", null: false
    t.integer "power", null: false
    t.string "scene", null: false
    t.integer "position", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
