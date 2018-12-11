class AddTrusttypeToManufacturer < ActiveRecord::Migration[5.2]
  def change
    add_column :manufacturers, :trust, :string, default: "unknown"
    add_index  :manufacturers, :trust
  end
end
