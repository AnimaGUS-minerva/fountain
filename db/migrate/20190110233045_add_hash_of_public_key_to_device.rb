class AddHashOfPublicKeyToDevice < ActiveRecord::Migration[5.2]
  def change
    add_column :devices, :idevid_hash, :text
    add_column :devices, :ldevid, :text
    add_column :devices, :ldevid_hash, :text
    add_index  :devices, :idevid_hash
    add_index  :devices, :ldevid_hash
  end
end
