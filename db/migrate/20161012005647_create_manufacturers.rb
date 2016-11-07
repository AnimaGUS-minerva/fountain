class CreateManufacturers < ActiveRecord::Migration
  def change
    create_table :manufacturers do |t|
      t.text :name

      t.timestamps null: false
    end
  end
end
