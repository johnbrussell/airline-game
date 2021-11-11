class AddIndexToAirportIata < ActiveRecord::Migration[6.1]
  def up
    add_index :airports, :iata, unique: true
  end

  def down
    remove_index :airports, name: "index_airports_on_iata"
  end
end
