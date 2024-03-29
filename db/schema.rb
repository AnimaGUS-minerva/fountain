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

ActiveRecord::Schema.define(version: 2019_01_10_223519) do

  create_table "administrators", force: :cascade do |t|
    t.text "name"
    t.boolean "admin", default: false
    t.boolean "enabled", default: false
    t.boolean "prospective", default: true
    t.binary "public_key"
    t.binary "previous_public_key"
    t.datetime "last_login"
    t.datetime "first_login"
    t.text "last_login_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "certificates", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "device_types", id: :serial, force: :cascade do |t|
    t.text "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "mud_url"
    t.text "mud_url_sig"
    t.json "validated_mud_json"
    t.integer "manufacturer_id"
    t.text "failure_details"
    t.boolean "mud_valid"
  end

  create_table "devices", id: :serial, force: :cascade do |t|
    t.text "name"
    t.text "fqdn"
    t.text "eui64"
    t.integer "device_type_id"
    t.integer "manufacturer_id"
    t.text "idevid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "traffic_counts"
    t.text "mud_url"
    t.integer "profile_id"
    t.text "current_vlan"
    t.boolean "wan_enabled"
    t.boolean "lan_enabled"
    t.json "firewall_rules"
    t.json "firewall_rule_names"
    t.boolean "deleted"
    t.boolean "quaranteed"
    t.boolean "device_enabled"
    t.text "device_state"
    t.json "failure_details"
    t.text "ipv4"
    t.text "ipv6"
    t.text "acp_prefix"
    t.text "idevid_hash"
    t.text "ldevid"
    t.text "ldevid_hash"
    t.text "wpa_key"
  end

  create_table "manufacturers", id: :serial, force: :cascade do |t|
    t.text "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "masa_url"
    t.binary "issuer_public_key"
    t.string "trust", default: "unknown"
    t.text "issuer_dn"
    t.string "certtype"
    t.index ["trust"], name: "index_manufacturers_on_trust"
  end

  create_table "system_variables", id: :serial, force: :cascade do |t|
    t.string "variable"
    t.string "value"
    t.integer "number"
  end

  create_table "voucher_requests", id: :serial, force: :cascade do |t|
    t.integer "device_id"
    t.integer "manufacturer_id"
    t.text "device_identifier"
    t.inet "requesting_ip"
    t.inet "proxy_ip"
    t.text "nonce"
    t.binary "idevid"
    t.boolean "signed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "tls_clientcert"
    t.binary "pledge_request"
    t.string "type", default: "CmsVoucherRequest"
    t.json "status"
    t.binary "registrar_request"
    t.binary "encoded_details"
  end

  create_table "vouchers", id: :serial, force: :cascade do |t|
    t.text "nonce"
    t.integer "manufacturer_id"
    t.integer "voucher_request_id"
    t.integer "device_id"
    t.text "device_identifier"
    t.date "expires_at"
    t.binary "signed_voucher"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type", default: "CmsVoucher"
    t.binary "encoded_details"
  end

end
