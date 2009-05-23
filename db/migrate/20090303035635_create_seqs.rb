class CreateSeqs < ActiveRecord::Migration
  def self.up
    create_table :seqs do |t|
      t.string :name, :null => false
      t.text :description, :null => false      
      t.string :gene
      t.text :seq, :null => false
      t.boolean :selected
      t.timestamps
    end
  end

  def self.down
    drop_table :seqs
  end
end
