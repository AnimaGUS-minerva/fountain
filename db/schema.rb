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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_11_21_234642) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "certificates", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "device_types", id: :serial, force: :cascade do |t|
    t.text "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "manufacturers", id: :serial, force: :cascade do |t|
    t.text "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "masa_url"
    t.binary "issuer_public_key"
  end

  create_table "nodes", id: :serial, force: :cascade do |t|
    t.text "name"
    t.text "fqdn"
    t.text "eui64"
    t.integer "device_type_id"
    t.integer "manufacturer_id"
    t.text "idevid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "system_variables", id: :serial, force: :cascade do |t|
    t.string "variable"
    t.string "value"
    t.integer "number"
  end

  create_table "voucher_requests", id: :serial, force: :cascade do |t|
    t.integer "node_id"
    t.integer "manufacturer_id"
    t.text "device_identifier"
    t.inet "requesting_ip"
    t.inet "proxy_ip"
    t.text "nonce"
    t.binary "idevid"
    t.json "details"
    t.boolean "signed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "tls_clientcert"
    t.binary "pledge_request"
    t.string "type", default: "CmsVoucherRequest"
    t.json "status"
    t.binary "registrar_request"
  end

  create_table "vouchers", id: :serial, force: :cascade do |t|
    t.text "nonce"
    t.integer "manufacturer_id"
    t.integer "voucher_request_id"
    t.integer "node_id"
    t.text "device_identifier"
    t.date "expires_at"
    t.json "details"
    t.binary "signed_voucher"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type", default: "CmsVoucher"
  end

end
