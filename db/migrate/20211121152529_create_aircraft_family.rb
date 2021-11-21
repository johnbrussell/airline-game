class CreateAircraftFamily < ActiveRecord::Migration[6.1]
  def up
    create_table :aircraft_family do |t|
      t.string :name, null: false, unique: true
      t.string :manufacturer, null: false

      t.timestamps
    end
  end

  def down
    drop_table :aircraft_family
  end
end
