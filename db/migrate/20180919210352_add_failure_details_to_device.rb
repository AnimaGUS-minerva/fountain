class AddFailureDetailsToDevice < ActiveRecord::Migration[5.2]
  def change
    add_column :devices, :failure_details, :json
  end
end
