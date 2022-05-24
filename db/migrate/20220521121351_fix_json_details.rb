class FixJsonDetails < ActiveRecord::Migration[5.2]
  def change
    remove_column :voucher_requests, :details, :json
    add_column :voucher_requests, :encoded_details, :binary
  end
end
