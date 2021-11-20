class CreateGates < ActiveRecord::Migration[6.1]
  def up
    create_table :gates do |t|
      t.belongs_to :airport
      t.belongs_to :game

      t.integer :current_gates, null: false

      t.timestamps
    end
  end

  def down
    drop_table :gates
  end
end
