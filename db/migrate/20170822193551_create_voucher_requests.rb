class CreateVoucherRequests < ActiveRecord::Migration[4.2]
  def change
    create_table :voucher_requests do |t|
      t.integer    :node_id
      t.integer    :manufacturer_id
      t.text       :device_identifier
      t.inet       :requesting_ip
      t.inet       :proxy_ip
      t.text       :nonce
      t.binary     :idevid
      t.json       :details
      t.boolean    :signed

      t.timestamps null: false
    end
  end
end
