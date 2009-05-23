class SeqController < ApplicationController

  # uses a single controller for now
  before_filter :get_vars 
   
  def index
    redirect_to :action => :files if @seqs.size == 0
  end

  # always called with ajax
  def add
    Seq.add_export_items(params)
    @total_export_items = ExportItem.count
      render :update do |page|
        params[:seq].keys.sort.each do |k| # loop the sequences selected
          s = Seq.find(k)
          page.replace_html "s#{k}", :partial => 'seq', :locals => {:i => params[:seq][k].split("_")[1], :g => s, :genes => s.gene}
          page.replace_html "export_items_count", :partial => 'count_export_items', :locals => {:count => @total_export_items}  
        end
      end
  end

  def file
    filename = params[:file_name].strip
    filename = "generator_#{Time.now.day}_#{Time.now.month}_#{Time.now.year}" if filename.size == 0 
    if params[:source_file]
      filename += '.sor'
      @data = ExportItem.source_file        
    else
      filename += '.dat'
      @data = ExportItem.file  
    end
    send_data @data, :type => "text/plain", :filename=> filename , :disposition => 'attachment' and return
    redirect_to :action => :index
  end

  def reset
   ExportItem.reset
   flash[:notice] = 'Reset.'
   redirect_to :action => :index
  end

  def nuke
    ExportItem.nuke
    redirect_to :action => :index
  end

  def status
    @genes = Seq.genes
    @export_items = ExportItem.find(:all)
  end

  def files
    flash.discard
    if request.post?
      if params[:file].blank? || params[:gene].blank? 
        flash[:notice] = "Provide both file and gene."
      else
        if Seq.load_file(params.update(:replace => (params[:replace] ? true : false )))
          flash[:notice] = "Loaded!"
        else
          flash[:notice] = "Error loading file."
        end
      end
    end
  end

  def delete_ei
    if ei = ExportItem.find(params[:id])
    ei.destroy
     render :update do |page|
       page.remove "ei#{ei.id}"
     end
    else
    end  
  end

  def delete_gene
    if Seq.delete_gene(params[:gene])
      flash[:notice] = "Success!"
    else
      flash[:notice] = "Something went horribly wrong."
    end
    redirect_to :action => :status
  end

  def autofill
    if  ExportItem.autofill(params[:mode])  
      flash[:notice] = "Success!"
    else 
      flash[:notice] = "Something went horribly wrong."
    end
    redirect_to :action => :status
  end

  def filter_by_motif
     if  Seq.filter_by_motif(params)  
      flash[:notice] = "Success!"
    else 
      flash[:notice] = "Something went horribly wrong."
    end
    redirect_to :action => :status
  end

  def filter_by_length
    if Seq.filter_by_length(params)
      flash[:notice] = "Success!"
    else 
      flash[:notice] = "Something went horribly wrong."
    end
    redirect_to :action => :status
  end


  def filter_by_mean_length
    if Seq.filter_by_length(params.update(:length => Seq.mean_length_by_gene(params[:gene])))
      flash[:notice] = "Success!"
    else 
      flash[:notice] = "Something went horribly wrong."
    end
    redirect_to :action => :status
  end

  protected

  def get_vars
    @seqs = Seq.find(:all, :order => "seqs.gene, seqs.name").group_by{|seq| seq.gene}
    @total_export_items = ExportItem.count
  end


end
