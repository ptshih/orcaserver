class PodController < ApplicationController
  
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
    controller.authenticate_token # sets the @current_user var based on passed in access_token (FB)
  end
  
  # Get index of pods
  # http://localhost:3000/v1/pods
  # http://orcapods.heroku.com/v1/pods?access_token=ab20afcd5def3b0cbc5f5352b63da16491a5715f3a0fbfd32179a8d73930532739525ca2387af8f8256d2b47a90af056cc013ced3dad56805852efc8080578b9
  def index
    
    @response_hash = {}
    
    resp = Pod.index(@current_user.id)
    response = []
    resp.each do |pod|
      response << {
        :id => pod['id'].to_s,
        :name => pod['name'],
        :fromId => pod['userid'].to_s,
        :fromName => pod['full_name'],
        :fromPictureUrl => "http://graph.facebook.com/"+pod['facebook_id'].to_s+"/picture?type=square",
        :message => pod['message'],
        :sequence => pod['hashid'],
        :participants => pod['participants'],
        :lat => nil,
        :lng => nil,
        :timestamp => pod['updated_at'].to_i,
        :logged_in_as => @current_user.full_name
      }
    end
    
    @response_hash['data'] = response
    
    # response = {:success => "true"}
    respond_to do |format|
      format.html
      format.xml  { render :xml => response_hash }
      format.json  { render :json => @response_hash }
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
    
    resp = Pod.message_index(params[:pod_id], @current_user.id)
    
    response = []
    resp.each do |message|
      
      attachmentUrl = nil
      if message['has_photo']==1
        attachmentUrl = "http://s3.amazonaws.com/orcapods/#{message['hashid']}.jpg"
      end
      response << {
          :id => message['id'].to_s,
          :podId => message['pod_id'].to_s,
          :sequence => message['hashid'],
          :fromId => message['userid'].to_s,
          :fromName => message['full_name'],
          :fromPictureUrl => "http://graph.facebook.com/"+message['facebook_id'].to_s+"/picture?type=square",
          :message => message['message'],
          :attachmentUrl => attachmentUrl,
          :photoWidth => message['photo_width'],
          :photoHeight => message['photo_height'],
          :lat => nil,
          :lng => nil,
          :timestamp => message['updated_at'].to_i
        }
    end
    
    @response_hash = {}
    @response_hash['data'] = response
    
    respond_to do |format|
      format.html
      format.xml  { render :xml => response_hash }
      format.json  { render :json => @response_hash }
    end
    
  end
  
  # Mute pod
  # @param REQUIRED access_token
  # @param REQUIRED pod_id
  # http://localhost:3000/v1/pods/3/members
  def members
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    response_hash = {}
    response = []
    resp = Pod.get_members(params[:pod_id])
    resp.each do |user|
      response << {
          :id => user['id'].to_s,
          :full_name => user['full_name'].to_s,
          :first_name => user['first_name'].to_s,
          :last_name => user['last_name'].to_s,
          :picture_url => "http://graph.facebook.com/"+user['facebook_id'].to_s+"/picture?type=square",
        }
    end
    response_hash['data'] = response
    respond_to do |format|
      format.xml  { render :xml => response_hash }
      format.json  { render :json => response_hash }
    end
    
  end
  
  # Mute pod
  # @param REQUIRED access_token
  # @param REQUIRED pod_id
  # http://localhost:3000/v1/pods/:id/mute/:hours
  # http://localhost:3000/v1/pods/1/mute/10
  def mute_pod
    
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    
    @current_user.mute_pod(params[:pod_id], param[:hours])
    
    response = {:success => "true"}
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
    
  end
  
  # Create new pod
  # @param REQUIRED access_token
  # @param REQUIRED name
  # http://localhost:3000/v1/pods/create?name=TestCreatePod&access_token=c7ae490c95c140716923383f2a25ddf46fd7b7f0afb768e0ccd36315dc1b91bbeb7e82e5faf303731a6fa6f106321bcb05d7bd2c1b7829087192057511ec550c
  # http://orcapods.heroku.com/v1/pods/create?name=TestCreatePod&access_token=c7ae490c95c140716923383f2a25ddf46fd7b7f0afb768e0ccd36315dc1b91bbeb7e82e5faf303731a6fa6f106321bcb05d7bd2c1b7829087192057511ec550c
  def new
    
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    
    if params[:sequence].nil?
      params[:sequence] = SecureRandom.hex(64)
    end
    
    newpod = Pod.create(
      :name => params[:name],
      :hashid => params[:sequence],
      :created_at => Time.now.utc.to_s(:db),
      :updated_at => Time.now.utc.to_s(:db)
    )
    response = newpod.add_user_to_pod(@current_user.id)
    # response = Pod.create(@current_user.id, params[:sequence], params[:name])
    
    response = {:success => "true"}
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
    
  end
  
  # Create message
  # @param REQUIRED access_token
  # @param REQUIRED pod_id
  # @param REQUIRED sequence
  # @param REQUIRED message
  # @param OPTIONAL has_photo
  # @param OPTIONAL photo_width
  # @param OPTIONAL photo_height
  # @param OPTIONAL metadata
  # @param OPTIONAL lat
  # @param OPTIONAL lng
  # http://localhost:3000/v1/pods/13/messages/create?message=helloworld832h4&access_token=
  # http://orcapods.heroku.com/v1/pods/13/messages/create?message=pictest&has_photo=1&sequence=1&photo_width=400&photo_height=300
  def message_new
    
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    
    if params[:sequence].nil?
      params[:sequence] = SecureRandom.hex(64)
    end
    
    # Change to use create_message_via_resque
    response = Pod.async_create_message(params[:pod_id], @current_user.id, @current_user.get_short_name, params[:sequence], params[:message], params[:has_photo], params[:photo_width], params[:photo_height], params[:metadata], params[:lat], params[:lng])
    #response = Pod.create_message(params[:pod_id], @current_user.id, @current_user.get_short_name, params[:sequence], params[:message], params[:has_photo], params[:photo_width], params[:photo_height], params[:metadata], params[:lat], params[:lng])
    
    response = {:success => "True: "+response}
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
    
  end
  
  # Add user to pod
  # @param REQUIRED access_token (user who is doing the adding)
  # @param REQUIRED pod_id
  # @param REQUIRED user_id (user who is being added)
  # http://orcapods.heroku.com/v1/pods/13/user/443/add?access_token=omgwtfbbqadmin
  def add_user
    
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    
    pod = Pod.find_by_id(params[:pod_id])
    response = pod.add_user_to_pod(params[:user_id], @current_user.id).to_s
    
    response = {:success => "True: "+response}
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
    
  end
  
  
  # Remove users from pod
  # @param REQUIRED access_token (user who is doing the adding)
  # @param REQUIRED pod_id
  # @param REQUIRED user_id
  # http://orcapods.heroku.com/v1/pods/13/user/443/add?access_token=omgwtfbbqadmin
  def remove_user
    
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    
    pod = Pod.find_by_id(params[:pod_id])
    response = pod.remove_user_from_pod(params[:user_id], @current_user.id).to_s
    
    response = {:success => "True: "+response}
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
    
  end
  
end