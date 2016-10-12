class CreateNodes < ActiveRecord::Migration
  def change
    create_table :nodes do |t|
      t.text :name
      t.text :fqdn
      t.text :eui64
      t.integer :device_type_id
      t.integer :manufacturer_id
      t.text :idevid

      t.timestamps null: false
    end
  end
end
