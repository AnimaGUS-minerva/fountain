class AddIpaddressesToDevices < ActiveRecord::Migration[5.2]
  def change
    add_column :devices, :ipv4, :text
    add_column :devices, :ipv6, :text
  end
end
