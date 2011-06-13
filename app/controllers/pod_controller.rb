class PodController < ApplicationController
  
  # Get index of pods
  # http://localhost:3000/v1/pod/index
  def index
    
    response = Pod.all
    
    # response = {:success => "true"}
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
    
  end
  
  # Get index of messages
  def message_index
    
    Rails.logger.info request.query_parameters.inspect
    
  end
  
  # Create new pod
  def new
    
    response = {:success => "true"}
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
    
  end
  
  # Create message
  def message_new
    
    
    
    response = {:success => "true"}
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
    
  end
  
end