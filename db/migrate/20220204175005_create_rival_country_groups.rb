class CreateRivalCountryGroups < ActiveRecord::Migration[6.1]
  def up
    create_table :rival_country_groups do |t|
      t.string :country_one, null: false
      t.string :country_two, null: false

      t.timestamps
    end
  end

  def down
    drop_table :rival_country_groups
  end
end
