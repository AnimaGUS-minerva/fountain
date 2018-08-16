class SetAdministratorDefaults < ActiveRecord::Migration[5.2]
  def change
    change_table :administrators do |t|
      t.change_default :admin,       false
      t.change_default :enabled,     false
      t.change_default :prospective, true
    end
    Administrator.all.each { |a|
      a.default_values
      a.save!
    }
  end
end
