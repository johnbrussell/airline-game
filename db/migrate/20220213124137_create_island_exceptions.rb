class CreateIslandExceptions < ActiveRecord::Migration[6.1]
  def up
    create_table :island_exceptions do |t|
      t.string :market_one
      t.string :market_two
      
      t.timestamps
    end
  end

  def down
    drop_table :island_exceptions
  end
end
