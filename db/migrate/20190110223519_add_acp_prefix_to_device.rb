class AddAcpPrefixToDevice < ActiveRecord::Migration[5.2]
  def change
    add_column :devices, :acp_prefix, :text
  end
end
