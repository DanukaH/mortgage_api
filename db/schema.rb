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

ActiveRecord::Schema[8.1].define(version: 2026_04_25_102841) do
  create_table "mortgage_applications", force: :cascade do |t|
    t.decimal "annual_income"
    t.datetime "assessed_at"
    t.datetime "created_at", null: false
    t.decimal "debt_to_income"
    t.string "decision"
    t.decimal "deposit_amount"
    t.text "explanation"
    t.decimal "loan_to_value"
    t.decimal "maximum_borrowing"
    t.decimal "monthly_expenses"
    t.decimal "property_value"
    t.string "status"
    t.integer "term_years"
    t.datetime "updated_at", null: false
  end
end
