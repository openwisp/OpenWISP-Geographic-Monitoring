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

ActiveRecord::Schema.define(:version => 20110706082525) do

  create_table "access_points", :id => false, :force => true do |t|
    t.integer  "id",              :default => 0, :null => false
    t.string   "hostname",                       :null => false
    t.float    "lat",                            :null => false
    t.float    "lng",                            :null => false
    t.string   "address",                        :null => false
    t.string   "city",                           :null => false
    t.string   "mng_ip"
    t.text     "description"
    t.string   "common_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "wisp_id"
    t.date     "activation_date"
  end

  create_table "activities", :force => true do |t|
    t.integer  "status"
    t.integer  "access_point_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activities", ["access_point_id"], :name => "index_activities_on_access_point_id"
  add_index "activities", ["created_at"], :name => "index_activities_on_created_at"

  create_table "activity_histories", :force => true do |t|
    t.float    "status"
    t.datetime "start_time"
    t.datetime "last_time"
    t.integer  "access_point_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activity_histories", ["access_point_id"], :name => "index_activity_histories_on_access_point_id"
  add_index "activity_histories", ["last_time"], :name => "index_activity_histories_on_last_time"
  add_index "activity_histories", ["start_time"], :name => "index_activity_histories_on_start_time"

  create_table "bdrb_job_queues", :force => true do |t|
    t.text     "args"
    t.string   "worker_name"
    t.string   "worker_method"
    t.string   "job_key"
    t.integer  "taken"
    t.integer  "finished"
    t.integer  "timeout"
    t.integer  "priority"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "archived_at"
    t.string   "tag"
    t.string   "submitter_info"
    t.string   "runner_info"
    t.string   "worker_key"
    t.datetime "scheduled_at"
  end

  create_table "configurations", :force => true do |t|
    t.string   "key",                        :null => false
    t.string   "value",      :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mac_vendors", :force => true do |t|
    t.string   "vendor"
    t.string   "oui"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "property_sets", :force => true do |t|
    t.boolean "reachable"
    t.integer "access_point_id"
    t.text    "notes"
    t.string  "site_description"
    t.boolean "public"
  end

  create_table "roles", :force => true do |t|
    t.string   "name",              :limit => 40
    t.string   "authorizable_type", :limit => 40
    t.integer  "authorizable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                               :default => "", :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "", :null => false
    t.string   "password_salt",                       :default => "", :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "username"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "wisps", :id => false, :force => true do |t|
    t.integer  "id",            :default => 0, :null => false
    t.string   "name",                         :null => false
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "owmw_url"
    t.string   "owmw_username"
    t.string   "owmw_password"
  end

end
