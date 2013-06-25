class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table :groups do |t|
      t.integer :wisp_id, :null => true
      t.string :name, :null => false
      t.text :description, :null => true
      t.boolean :monitor, :default => true
      t.integer :total, :default => 0
      t.integer :up, :default => 0
      t.integer :down, :default => 0
      t.integer :unknown, :default => 0
      t.timestamps
    end
    
    group = Group.create(:id => 1, :name => 'No Group', :description => 'Default Group')
    
    add_column :property_sets, :group_id, :integer, :default => 1
  end

  def self.down
    drop_table :groups
    remove_column :property_sets, :group_id
  end
end
