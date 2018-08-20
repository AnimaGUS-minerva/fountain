class RenameNodeReferencesToDevice < ActiveRecord::Migration[5.2]
  def change
    rename_column :voucher_requests, :node_id, :device_id
    rename_column :vouchers, :node_id, :device_id
  end
end
