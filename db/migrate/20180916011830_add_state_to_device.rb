class AddStateToDevice < ActiveRecord::Migration[5.2]
  def change
    add_column :devices, :device_state, :text
  end
end
