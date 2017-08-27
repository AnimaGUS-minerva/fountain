class CreateVouchers < ActiveRecord::Migration
  def change
    create_table :vouchers do |t|
      t.text    :nonce
      t.integer :manufacturer_id
      t.integer :voucher_request_id
      t.integer  :node_id
      t.text    :device_identifier
      t.date    :expires_at
      t.json    :details
      t.binary  :signed_voucher
      t.timestamps null: false
    end
  end
end
