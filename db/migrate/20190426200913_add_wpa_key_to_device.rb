class AddWpaKeyToDevice < ActiveRecord::Migration[5.2]
  def change
    add_column :devices, :wpa_key, :text
  end
end
