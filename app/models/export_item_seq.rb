class ExportItemSeq < ActiveRecord::Base
  acts_as_list :scope => :export_item
  belongs_to :seq
  belongs_to :export_item

  before_destroy  :update_seqs

  named_scope :by_gene, lambda {|*args| {:include => :seq, :conditions => ["seqs.gene = ?", (args.first || -1)] }}

  # reset the chosen flags on seqs if no other EI is using the seq when the EI is deleted
  def update_seqs
      if ExportItemSeq.find_all_by_seq_id(self.seq_id).size == 1 # there is only one, must be this one
        Seq.find(self.seq_id).update_attributes(:selected => false)
      end
  end

end
