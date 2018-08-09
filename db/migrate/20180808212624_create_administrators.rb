class CreateAdministrators < ActiveRecord::Migration[5.2]
  def change
    create_table :administrators do |t|
      t.text     :name
      t.boolean  :admin
      t.boolean  :enabled
      t.boolean  :prospective
      t.binary   :public_key
      t.binary   :previous_public_key
      t.datetime :last_login
      t.datetime :first_login
      t.text     :last_login_ip

      t.timestamps
    end
  end
end
