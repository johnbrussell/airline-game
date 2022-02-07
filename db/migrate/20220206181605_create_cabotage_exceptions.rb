class CreateCabotageExceptions < ActiveRecord::Migration[6.1]
  def up
    create_table :cabotage_exceptions do |t|
      t.string :country, null: false
      t.string :excepted_country_group

      t.timestamps
    end
  end

  def down
    drop_table :cabotage_exceptions
  end
end
