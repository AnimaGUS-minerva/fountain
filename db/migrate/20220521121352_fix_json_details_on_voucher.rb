class FixJsonDetailsOnVoucher < ActiveRecord::Migration[5.2]
  def change
    remove_column :vouchers, :details, :json
    add_column :vouchers, :encoded_details, :binary
  end
end
