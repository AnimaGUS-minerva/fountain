class AddFailureDetailsToDeviceType < ActiveRecord::Migration[5.2]
  def change
    add_column :device_types, :failure_details, :text
    add_column :device_types, :mud_valid, :boolean
  end
end
