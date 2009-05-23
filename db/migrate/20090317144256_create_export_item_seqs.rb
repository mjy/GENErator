class CreateExportItemSeqs < ActiveRecord::Migration
def self.up
    create_table :export_item_seqs do |t|
      t.integer :seq_id, :null => false
      t.integer :export_item_id, :null => false
      t.integer :position
      t.timestamps
    end
  end

  def self.down
    drop_table :export_items
  end
end
