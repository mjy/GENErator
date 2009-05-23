$USAGE = 'Call like: "rake generator:load_seqs gene=<some_gene> file=<some_full_path_to_file>"'

namespace :generator do
  desc $USAGE
  task :load_seqs => [:environment] do
  
    @file = ENV['file']
    @labels = ENV['labels'] || 'standard'
    raise "Unable to read from file '#{@file}'" if !File.readable?(@file)   
    ff = File.open(@file)
    print "Reading"
    Seq.input_file(:file =>ff, from_rake => true, :labels => @labels)
   
  end
end
