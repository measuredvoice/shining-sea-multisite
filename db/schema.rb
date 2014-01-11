# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140110190416) do

  create_table "accounts", :force => true do |t|
    t.integer  "site_id"
    t.string   "screen_name"
    t.string   "user_id"
    t.string   "name"
    t.integer  "followers"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "accounts", ["site_id", "screen_name"], :name => "index_accounts_on_site_id_and_screen_name"

  create_table "rails_admin_histories", :force => true do |t|
    t.text     "message"
    t.string   "username"
    t.integer  "item"
    t.string   "table"
    t.integer  "month",      :limit => 2
    t.integer  "year",       :limit => 8
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  add_index "rails_admin_histories", ["item", "table", "month", "year"], :name => "index_rails_admin_histories"

  create_table "sites", :force => true do |t|
    t.string   "name"
    t.string   "host_url"
    t.text     "registry_csv_url"
    t.text     "tagline"
    t.string   "tweet_type"
    t.string   "account_type"
    t.text     "explanation"
    t.text     "cta_iframe"
    t.string   "time_zone"
    t.boolean  "active",                   :default => false
    t.boolean  "send_congrats",            :default => false
    t.text     "twitter_client_key"
    t.text     "twitter_client_secret"
    t.text     "twitter_retweeter_key"
    t.text     "twitter_retweeter_secret"
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.string   "twitter_account_username"
    t.string   "mv_partner_name"
    t.text     "partner_logo_url"
    t.string   "google_analytics_code"
    t.string   "congrats_text"
  end

  add_index "sites", ["active"], :name => "index_sites_on_active"
  add_index "sites", ["host_url"], :name => "index_sites_on_host_url"

  create_table "tweet_metrics", :force => true do |t|
    t.integer  "account_id"
    t.string   "tweet_id"
    t.datetime "published_at"
    t.integer  "audience"
    t.integer  "reach"
    t.integer  "kudos"
    t.integer  "engagement"
    t.string   "tweet_text"
    t.boolean  "metrics_ready", :default => false
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  add_index "tweet_metrics", ["account_id", "metrics_ready"], :name => "index_tweet_metrics_on_account_id_and_metrics_ready"

  create_table "users", :force => true do |t|
    t.string   "email",               :default => "", :null => false
    t.string   "encrypted_password",  :default => "", :null => false
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",       :default => 0,  :null => false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true

end
