class RenameNodeToDevices < ActiveRecord::Migration[5.2]
  def change
    rename_table :nodes, :devices
  end
end
