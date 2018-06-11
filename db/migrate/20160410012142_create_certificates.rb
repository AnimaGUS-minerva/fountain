class CreateCertificates < ActiveRecord::Migration[4.2]
  def change
    create_table :certificates do |t|

      t.timestamps null: false
    end
  end
end
