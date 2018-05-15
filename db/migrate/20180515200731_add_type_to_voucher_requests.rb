class AddTypeToVoucherRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :voucher_requests, :type, :string, :default => 'CmsVoucherRequest'
  end
end
