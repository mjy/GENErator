class ExportItem < ActiveRecord::Base
  
  has_many :export_item_seqs, :dependent => :destroy
  has_many :seqs, :through => :export_item_seqs, :order => 'seqs.gene'

  named_scope :by_gene, lambda {|*args| {:include => :seqs, :conditions => ["seqs.gene = ?", (args.first || -1)] }}

  # this only counts correctly if a single seq from each column is chosen
  def self.length_longest_seq_of_gene(gene)
    l = 0
    self.by_gene(gene).each do |ei|
      ei.seqs.each do |s|
        l = s.seq.length if s.seq.length > l
      end
    end
    l
  end
  
  # generates the text for the .da file
  def self.file
    str = ''
    str << self.find(:all).size.to_s
    str << " terminals\n"
    Seq.genes.each do |g|
      max_length = self.length_longest_seq_of_gene(g)
      str << "\n\n#{g} (length: #{max_length})\n\n"
      str << "\n"
      self.find(:all).each do |ei|
        cur_seqs = ei.export_item_seqs.by_gene(g)
        str << ei.name.ljust(28)
        str << "#{cur_seqs.collect{|q| q.seq.seq}.join(" ").ljust(max_length, "-")}"
        str << "\n"
      end
    end
    str
  end

  # generates the text for the .sor file
  def self.source_file
    str = "GENErator source file\n\n"

    self.find(:all).each_with_index do |ei, i|
      str << "#{ei.name}:\n"
      cur_seqs = ei.seqs
      str << cur_seqs.collect{|s| "#{s.gene}: #{s.description}"}.join("\n")
      str << "\n\n"
    end
    str
  end

  # removes all the ExportItems from the project
  def self.reset
    ExportItem.find(:all).each do |i|
      i.destroy
    end
    Seq.find(:all).each do |s|
      s.update_attributes(:selected => false)
    end
    true
  end
 
  # removes all the data from the project
  def self.nuke
    ExportItem.find(:all).each do |i|
      i.destroy
    end
    Seq.find(:all).each do |s|
      s.destroy
    end
    true
  end

  # create terminals for all matching
  def self.autofill(mode = :complete)
    @genes = Seq.genes
    case mode.to_sym
    when :complete
      @has_all = []
      # logic is a little lame here, but meh
      Seq.unique_terminal_names.each do |n|
        i = 0
        @genes.each do |g|
          i += 1 if Seq.find_all_by_gene_and_description(g, n).size > 0
        end
        @has_all.push(n) if i == @genes.size
      end
      # seq needs to look like:  {"name"=>"",  "seq"=>{"209"=>"B_1", "203"=>"4_2", "214"=>"test_4"}}
    
      # now build
      @has_all.each do |n|
        seq = {}
        @genes.each do |g|
          s = Seq.find_by_gene_and_description(g, n)
          seq.update(s.id.to_s => g.to_s) if s
        end
        Seq.add_export_items(:name => '', :seq => seq )
      end

    when :all
      Seq.unique_terminal_names.each do |n|
        seq = {}
        @genes.each do |g|
          s = Seq.find_by_gene_and_description(g, n)
          seq.update(s.id.to_s => g.to_s) if s
         end
        Seq.add_export_items(:name => '', :seq => seq)  
      end
    else
      return false
    end

  end

  protected


end
