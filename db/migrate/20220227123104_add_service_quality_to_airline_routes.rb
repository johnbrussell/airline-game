class AddServiceQualityToAirlineRoutes < ActiveRecord::Migration[6.1]
  def up
    add_column :airline_routes, :service_quality, :integer, null: false, default: 1
  end

  def down
    remove_column :airline_routes, :service_quality
  end
end
