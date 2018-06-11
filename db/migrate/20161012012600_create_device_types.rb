class CreateDeviceTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :device_types do |t|
      t.text :name

      t.timestamps null: false
    end
  end
end
