class AddTypeToVoucher < ActiveRecord::Migration[5.2]
  def change
    add_column :vouchers, :type, :string, :default => 'CmsVoucher'
  end
end
