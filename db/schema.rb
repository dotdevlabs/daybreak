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

ActiveRecord::Schema[8.1].define(version: 2026_08_14_113817) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "agent_endpoints", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "callback_url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_agent_endpoints_on_account_id"
  end

  create_table "api_tokens", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_api_tokens_on_account_id"
    t.index ["token"], name: "index_api_tokens_on_token", unique: true
  end

  create_table "credentials", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.string "nickname"
    t.string "public_key", null: false
    t.integer "sign_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["external_id"], name: "index_credentials_on_external_id", unique: true
    t.index ["user_id"], name: "index_credentials_on_user_id"
  end

  create_table "daily_briefings", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.jsonb "action_items_data", default: {}, null: false
    t.jsonb "agent_activity_data", default: [], null: false
    t.jsonb "calendar_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.jsonb "daily_goals_data", default: {}, null: false
    t.date "date", null: false
    t.jsonb "long_term_goals_data", default: [], null: false
    t.datetime "updated_at", null: false
    t.jsonb "weather_data", default: {}, null: false
    t.index ["account_id", "date"], name: "index_daily_briefings_on_account_id_and_date", unique: true
    t.index ["account_id"], name: "index_daily_briefings_on_account_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "locale"
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.string "webauthn_id", null: false
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["webauthn_id"], name: "index_users_on_webauthn_id", unique: true
  end

  add_foreign_key "agent_endpoints", "accounts"
  add_foreign_key "api_tokens", "accounts"
  add_foreign_key "credentials", "users"
  add_foreign_key "daily_briefings", "accounts"
  add_foreign_key "sessions", "users"
  add_foreign_key "users", "accounts"
end
