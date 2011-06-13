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
  
  # Get index of messages: list of messages from a pod
  # @param REQUIRED access_token
  # @param REQUIRED pod_id
  def message_index
    
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    
    # Change to use create_message_via_resque
    Pod.create_message(params[:pod_id], params[:message_uuid], params[:message])
    
    response = {:success => "true"}
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
    
  end
  
  # Create new pod
  # @param REQUIRED access_token
  # @param REQUIRED name
  def new
    
    response = {:success => "true"}
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
    
  end
  
  # Create message
  # @param REQUIRED access_token
  # @param REQUIRED pod_id
  # @param REQUIRED message_uuid
  # @param REQUIRED message
  # http://localhost:3000/v1/pod/1/message/create?message='helloworld!'
  def message_new
    
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    
    params[:message_uuid] = rand
    params[:user_id] = 123
    
    # Change to use create_message_via_resque
    response = Pod.create_message(params[:pod_id], params[:message_uuid], params[:message])
    
    response = {:success => "True: "+response}
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
    
  end
  
end