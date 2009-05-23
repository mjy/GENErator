class Seq < ActiveRecord::Base

  has_many :export_item_seqs, :dependent => :destroy
  has_many :export_items, :through => :export_item_seqs

  named_scope :by_gene, lambda {|*args| {:conditions => ["seqs.gene = ?", (args.first || -1)] }}

  # adds an item (terminal) 
  def self.add_export_items(options = {})   
    seqs = []
    tmp_name = nil
    ei = ExportItem.new
   
    options[:seq].keys.sort.each do |k|
      s = Seq.find(k)
      tmp_name ||= s.name 
      s.update_attributes(:selected => true)
      ei.seqs << s
    end
    ei.name = options[:name].blank? ? tmp_name : options[:name] 
    ei.save
  end

  # returns a list of genes
  def self.genes
    Seq.find_by_sql('select distinct gene from seqs;').collect{|s| s.gene}.sort
  end

  def self.unique_terminal_names
    Seq.find_by_sql('select distinct description from seqs;').collect{|s| s.description}.sort
  end

  def self.mean_length_by_gene(gene)
      length = 0
      i = 0
      Seq.by_gene(gene).each do |s|
        length += s.seq.length
        i += 1
      end
      return 0 if length == 0
     length / i
  end

  # mession with Bio::Sequence
  def self.bio_seq_mean_stats_by_gene(gene)
    # concat the data (doing a mean here)
    concat = ''
    gc_content = 0
    gc_skew = 0
    gc_percent = 0
    at_skew = 0
    at_content = 0
    molecular_weight = 0
    a = 0
    c = 0
    g = 0
    t = 0

    i = 0
     Seq.by_gene(gene).each do |s|
      concat += s.seq
      tmp = Bio::Sequence::NA.new("#{s.seq}")
      
  # methods not working   
  #      gc_content += t.gc_content
  #      gc_skew += t.gc_skew
      gc_percent += tmp.gc_percent
  #    at_skew += t.at_skew
  #    at_content += t.at_content
      molecular_weight += tmp.molecular_weight
      f = tmp.composition
      a += f['a'].to_i || 0
      c += f['c'].to_i || 0
      g += f['g'].to_i || 0
      t += f['t'].to_i || 0
      i += 1
     end
     s = Bio::Sequence::NA.new(concat)

     { #:gc_content => gc_content / i, 
       #:gc_skew => gc_skew /i,
       :gc_percent => gc_percent / i,
      # :at_skew => at_skew / i,
      # :at_content => at_content /i,
       :illegal_bases => s.illegal_bases,
       :molecular_weight => molecular_weight /i,
       :a => a/i,
       :c => c/i,
       :g => g/i,
       :t => t/i
     }
  end

  protected 

  def self.load_file(options = {})
    opts = {
      :file => nil,
      :gene => nil,
      :from_rake => false,
      :labels => 'standard', 
      :replace => false
    }.merge!(options.symbolize_keys)

    
    return false if !opts[:gene] || !opts[:file]

    ff = Bio::FlatFile.auto(opts[:file])
    
    print "Reading" if opts[:from_rake]

    i = 0
    begin
      ActiveRecord::Base.transaction do
        ff.each_entry do |seq|
          if opts[:labels] == "custom"
            foo = seq.definition.split("_")
            foo.shift if (foo[0] =~ /\d/)  # first pass
            foo.shift if (foo[0] =~ /\d/)  # second pass
            n = foo.join("_")
          else
            n = seq.identifiers.descriptions.join(" ")[0..24]
          end

          n = seq.definition[0..24] if n.strip.size == 0 # in a non-standard fasta label drop back and use the whole label

          if opts[:replace]
            s = Seq.find_by_gene_and_description(opts[:gene], n)
            s.update_attributes(:seq => seq.seq) if s
          else
            s = Seq.new(:gene => opts[:gene], :seq => seq.seq, :name => n, :description => seq.definition)
            s.save
          end

          print "."  if opts[:from_rake]
          i +=1
        end
        print "done (#{i})\n"  if opts[:from_rake]
      end
    rescue
      return false
    end
    true
  end

  # removes all sequences, and EIs of a given gene
  def self.delete_gene(gene)
     Seq.find(:all).each do |s|
       s.destroy if s.gene == gene
     end

      Seq.cleanup_export_items

     true
  end

  # removes all sequences with(out) a provided motif
  def self.filter_by_motif(options = {})
    opts = {:motif => '', :mode => :exclude}.merge!(options.symbolize_keys)
    return false if opts[:motif].size == 0

    # if seq doesn't have motif delete it
    if opts[:exclude]  
      Seq.find(:all).each do |s|
        
        s.destroy if ((s.seq =~ /#{opts[:motif]}/) == nil)
      end

    # if seq HAS motif delete it
    elsif opts[:include]
      Seq.find(:all).each do |s|
        s.destroy if !((s.seq =~ /#{opts[:motif]}/)  == nil)
      end

    else
      return false
    end

    Seq.cleanup_export_items
  end

  # used for both mean and absolute
  def self.filter_by_length(options = {})
    opts = {:length => 0, :gene => nil}.merge!(options.symbolize_keys)
    return false if opts[:length] == 0

    # if seq doesn't have motif delete it
    if opts[:less_than]  
      Seq.find(:all).each do |s|
        s.destroy if s.seq.size < opts[:length].to_i
      end

    # if seq HAS motif delete it
    elsif opts[:greater_than]
      Seq.find(:all).each do |s|
        s.destroy if s.seq.size > opts[:length].to_i
      end

    else
      return false
    end

    Seq.cleanup_export_items

  end

  def self.cleanup_export_items
    # loop terminals, if they have no data delete them 
      ExportItem.find(:all).each do |ei|
        ei.destroy if ei.seqs.size == 0
      end
  end

  

end
