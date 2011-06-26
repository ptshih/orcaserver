require 'rubygems'
require 'typhoeus'
require 'json'

class PodController < ApplicationController
  
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
    controller.authenticate_token # sets the @current_user var based on passed in access_token (FB)
  end
  
  # Get index of pods
  # http://localhost:3000/v1/pods
  # http://orcapods.heroku.com/v1/pods?access_token=omgwtfbbqadmin
  def index
    
    @response_hash = {}
    
    resp = Pod.index(@current_user.id)
    response = []
    resp.each do |pod|
      response << {
        :id => pod['id'].to_s,
        :name => pod['name'],
        :from_id => pod['userid'].to_s,
        :from_name => pod['full_name'],
        :from_picture_url => "http://graph.facebook.com/"+pod['facebook_id'].to_s+"/picture?type=square",
        :sequence => pod['sequence'],
        :participants => pod['participants'],
        :metadata => pod['metadata'],
        :timestamp => pod['updated_at'].to_i
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
      response << {
          :id => message['id'].to_s,
          :pod_id => message['pod_id'].to_s,
          :sequence => message['sequence'].to_s,
          :from_id => message['user_id'].to_s,
          :from_name => message['full_name'],
          :from_picture_url => "http://graph.facebook.com/"+message['facebook_id'].to_s+"/picture?type=square",
          :message_type => message['message_type'],
          :metadata => message['metadata'],
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
  # http://orcapods.heroku.com/v1/pods/3/members
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
    
    @current_user.mute_pod(params[:pod_id], params[:hours].to_i)
    
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
      params[:sequence] = UUIDTools::UUID.random_create.to_s
    end
    
    newpod = Pod.create(
      :name => params[:name],
      :sequence => params[:sequence],
      :created_at => Time.now.utc.to_s(:db),
      :updated_at => Time.now.utc.to_s(:db)
    )
    response = newpod.add_user_to_pod(@current_user.id, @current_user.id)
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
  # @param OPTIONAL photo_url
  # @param OPTIONAL photo_width
  # @param OPTIONAL photo_height
  # @param OPTIONAL lat
  # @param OPTIONAL lng
  # http://localhost:3000/v1/pods/16/messages/create?message=blahfirstmessageya
  # http://orcapods.heroku.com/v1/pods/13/messages/create?message=pictest&photo_url=XXX&sequence=1&photo_width=400&photo_height=300
  def message_new
    
    # Rails.logger.info request.query_parameters.inspect
    # puts "params: #{params}"
    
    # access_key_id: AKIAJRFSK3RWQ7XLGNFA
    # secret_access_key: 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
    
    if params[:sequence].nil?
      params[:sequence] = UUIDTools::UUID.random_create.to_s
    end
    
    # Upload file to AWS S3 (DEPRECATED)
    # photo = params['photo']
    # if not photo.nil?
    #   photo_file_name = photo.original_filename
    #   photo_file = photo.tempfile
    #   AWS::S3::Base.establish_connection!(
    #     :access_key_id     => 'AKIAJRFSK3RWQ7XLGNFA',
    #     :secret_access_key => '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'
    #   )
    #   AWS::S3::S3Object.store(photo_file_name, open(photo_file), 'orcapods', :access => :public_read)
    # end
    
    # for fun
    if params['pod_id']=='2'
      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'
      phash = Hash.new
      base_url = "https://www.googleapis.com/language/translate/v2"
      phash['key'] = "AIzaSyC8p9ghNKKOTGz3NZNQPo564JJXbHKZSME"
      phash['source']="en"
      phash['q'] = params[:message]
      phash['target']= "zh-TW"
      translateresponse = Typhoeus::Request.get(base_url, :params => phash, :headers => headers_hash, :disable_ssl_peer_verification => true)
      trans_resp = JSON.parse(translateresponse.body)
      
      #params[:message] = 'translate '+trans_resp['data']['translations'][0]
      if !trans_resp['data'].nil?
        if !trans_resp['data']['translations'].nil?
          if !trans_resp['data']['translations'][0]['translatedText'].nil?
            params[:message] = trans_resp['data']['translations'][0]['translatedText']
          end
        end
      end # end check response
    end

    # metadata = JSON.generate metadata_hash (or use JSON.pretty_generate but waste of space)
    # metadata_hash = JSON.parse metadata
    # http://flori.github.com/json/doc/index.html
    # metadata_hash = {}
    # param_ignore_list = ['controller','version', 'message', 'sequence', 'access_token', 'pod_id', '(null)']
    # params.each do |key, value|
    #   # Store the param if it's not in the ignore list
    #   if !param_ignore_list.include?(key) && !key.nil?
    #     metadata_hash[key] = value
    #   end
    # end
    # 
    # metadata = JSON.generate metadata_hash
    metadata = JSON.parse params['metadata']
    puts "metadata: #{metadata}"
    # Create message back
    if params['message_type'] == 'link' || params['message_type']=='youtube'
      url = metadata['message']
      puts "url: #{url}"
      Article.fetch_diffbot_article(url)
      v_md5 = Digest::MD5.hexdigest(url)
      query = "select * from articles where v_md5 = '#{v_md5}'"
      qresult = ActiveRecord::Base.connection.execute(query)
      qresult.each(:as => :hash) do |row|
        
        media = JSON.parse row['media']
        media.each do |media_child|
          # Default sets a primary images
          if media_child['primary']=='true' && media_child['type']=='image' && !media_child['link'].nil?
            metadata['link_thumbnail_url'] = media_child['link']
          # Otherwise create thumbnail for youtube
          elsif media_child['type']=='video' && params['message_type']=='youtube'
            video_key = media_child['link'][29..100]
            metadata['link_thumbnail_url'] = 'http://i4.ytimg.com/vi/#{video_key}/default.jpg'
          end
        end
        
        metadata['link_title'] = row['title']
        metadata['link_source'] = row['url']
        metadata['link_summary'] = row['summary']
        
      end
      
    end
    
    # Change to use create_message_via_resque
    if not params.nil?
      params_hash = {}
      params_hash['user_id'] = @current_user.id
      params_hash['user_short_name'] = @current_user.get_short_name
      params_hash['pod_id'] = params['pod_id']
      params_hash['sequence'] = params['sequence']
      params_hash['message_type'] = params['message_type']
      params_hash['metadata'] = JSON.generate metadata
      
      params_json = JSON.generate params_hash
        
      response = Pod.async_create_message(params_json)
    end
        
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
  # http://orcapods.heroku.com/v1/pods/13/user/443/remove?access_token=omgwtfbbqadmin
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
  
  # Change pod name
  # @param REQUIRED access_token (user who is doing the adding)
  # @param REQUIRED pod_id
  # @param REQUIRED pod_name
  # http://orcapods.heroku.com/v1/pods/13/change_name?access_token=omgwtfbbqadmin
  # http://localhost:3000/v1/pods/13/change_name?access_token=omgwtfbbqadmin
  def change_pod_name
    
    Rails.logger.info request.query_parameters.inspect
    puts "params: #{params}"
    
    # pod = Pod.find_by_id(params[:pod_id])
    response = Pod.change_name(params[:pod_name], @current_user.id, params[:pod_id])
    
    response = {:success => "True: "+response}
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
    
  end
  
end