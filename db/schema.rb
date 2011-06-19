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

ActiveRecord::Schema.define(:version => 0) do

  create_table "friendships", :primary_key => "user_id", :force => true do |t|
    t.integer "friend_id",   :limit => 8
    t.string  "friend_name"
  end

  create_table "messages", :force => true do |t|
    t.integer  "pod_id",     :limit => 8,                                 :default => 0
    t.integer  "user_id",    :limit => 8,                                 :default => 0
    t.string   "hashid"
    t.string   "message"
    t.integer  "attachment_url"
    t.text     "metadata"
    t.decimal  "lat",                     :precision => 20, :scale => 16
    t.decimal  "lng",                     :precision => 20, :scale => 16
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "messages", ["pod_id"], :name => "idx_pod_id"
  add_index "messages", ["user_id"], :name => "idx_user_id"

  create_table "pods", :force => true do |t|
    t.string   "name"
    t.text     "metadata"
    t.string   "hashid"
    t.integer  "last_message_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pods", ["last_message_id"], :name => "idx_last_snap_id"
  add_index "pods", ["name"], :name => "idx_name"
  add_index "pods", ["updated_at"], :name => "idx_updated_at"

  create_table "pods_users", :id => false, :force => true do |t|
    t.integer  "user_id",    :limit => 8, :default => 0
    t.integer  "pod_id",     :limit => 8, :default => 0
    t.datetime "mute_until"
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "pods_users", ["user_id", "pod_id"], :name => "idx_unique_user_id_and_pod_id", :unique => true

  create_table "users", :force => true do |t|
    t.integer  "facebook_id",           :limit => 8
    t.string   "access_token"
    t.string   "facebook_access_token"
    t.string   "last_message_hashid"
    t.string   "udid"
    t.string   "device_token"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "full_name"
    t.string   "locale",                :limit => 45
    t.datetime "joined_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["facebook_id"], :name => "facebook_id_UNIQUE", :unique => true

  create_table "v_messages", :id => false, :force => true do |t|
    t.string   "name"
    t.integer  "pod_id",     :default => 0, :null => false
    t.string   "full_name"
    t.integer  "user_id",    :default => 0, :null => false
    t.string   "message"
    t.datetime "created_at"
  end

end
