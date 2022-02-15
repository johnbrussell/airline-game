class AddIndexToYears < ActiveRecord::Migration[6.1]
  def up
    add_index :populations, :year
    add_index :tourists, :year
  end

  def down
    remove_index :populations, :year
    remove_index :tourists, :year
  end
end
