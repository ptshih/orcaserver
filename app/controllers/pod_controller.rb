class PodController < ApplicationController
  
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
    controller.authenticate_token # sets the @current_user var based on passed in access_token (FB)
  end
  
  # Get index of pods
  # http://localhost:3000/v1/pods
  def index
    
    response = Pod.index(@current_user.id)
    
    response_hash = {}
    response_hash['data'] = response
    
    # response = {:success => "true"}
    respond_to do |format|
      format.xml  { render :xml => response_hash }
      format.json  { render :json => response_hash }
    end
    
  end
  
  # Get index of messages: list of messages from a pod
  # @param REQUIRED access_token
  # @param REQUIRED pod_id
  # http://localhost:3000/v1/pods/1/messages
  # http://orcapods.heroku.com/v1/pods/1/messages
  def message_index
    
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    
    response = Pod.message_index(params[:pod_id])
    
    response_array = []
    response.each do |message|
      response_array << {
        :id => message['id'],
        :podId => nil,
        :sequence => nil,
        :fromId => nil,
        :fromPictureUrl => nil,
        :message => nil,
        :lat => nil,
        :lng => nil,
        :timestamp => nil
      }
    end
    
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response_array }
    end
    
  end
  
  # Create new pod
  # @param REQUIRED access_token
  # @param REQUIRED name
  # http://localhost:3000/v1/pods/create?name=pod123&access_token=1
  def new
    
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    
    response = Pod.create(@current_user.id, params[:name])
    
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
  # http://localhost:3000/v1/pods/1/messages/create?message=helloworld832h4&access_token=1
  def message_new
    
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    
    if params[:sequence].nil?
      params[:sequence] = rand
    end
    params[:user_id] = 123
    params[:message] += "from user #{@current_user.id}"
    
    # Change to use create_message_via_resque
    response = Pod.async_create_message(params[:pod_id], params[:user_id], params[:sequence], params[:message])
    # response = Pod.create_message(params[:pod_id], params[:user_id], params[:message_uuid], params[:message])
    
    response = {:success => "True: "+response}
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
    
  end
  
end