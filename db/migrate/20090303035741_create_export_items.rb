class CreateExportItems < ActiveRecord::Migration
  def self.up
    create_table :export_items do |t|
      t.string :name, :null => false
      t.text :comment
      t.integer :position
      t.timestamps
    end
  end

  def self.down
    drop_table :export_items
  end
end
