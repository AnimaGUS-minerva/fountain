class AddPledgeSignedToVoucherRequest < ActiveRecord::Migration
  def change
    add_column :voucher_requests, :pledge_request, :binary
  end
end
