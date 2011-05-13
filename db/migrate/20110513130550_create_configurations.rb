class CreateConfigurations < ActiveRecord::Migration
  def self.up
    create_table :configurations do |t|
      t.string  :key,        :null => false
      t.string  :value,      :null => false, :default => ''

      t.timestamps
    end
  end

  def self.down
    drop_table :configurations
  end
end
