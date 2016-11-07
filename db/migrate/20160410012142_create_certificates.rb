class CreateCertificates < ActiveRecord::Migration
  def change
    create_table :certificates do |t|

      t.timestamps null: false
    end
  end
end
