require 'rubygems'
require 'typhoeus'
require 'json'

class LoginController < ApplicationController
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
    @@peter_id = 548430564
    @@james_id = 645750651
    @@tom_id = 480460
    @@fb_host = 'https://graph.facebook.com'
    @@fb_app_id = '147806651932979'
    @@fb_app_secret = '587e59801ee014c9fdea54ad17e626c6'
    @@fb_app_access_token = "132514440148709%257Cf09dd88ba268a8727e4f3fd5-645750651%257Ck21j0yXPGxYGbJPd0eOEMTy5ZN4"
    
  end
  
  ###
  ### Convenience Methods
  ###
  
  def find_friends_for_current_user
    # last_fetched_friends = @current_user.last_fetched_friends
    # puts "Last fetched friends before: #{last_fetched_friends}"

    # Get all friends from facebook for the current user again
    LoginController.find_friends_for_facebook_id(@current_user.facebook_id, nil)
    
    return true
  end
  
  # API registers a new first time User from a client
  # Receives a POST with facebook_access_token from the user
  #   :facebook_access_token
  #   :facebook_id
  #   :facebook_name
  #   :first_name
  #   :last_name
  # Returns our access_token to the client along
  # http://localhost:3000/v1/register?facebook_id=645750651&facebook_access_token=132514440148709%257Cf09dd88ba268a8727e4f3fd5-645750651%257Ck21j0yXPGxYGbJPd0eOEMTy5ZN4&first_name=James&last_name=Liu&facebook_name=James Liu
  def register
    
    # Create a new user if necessary
    @current_user = User.find_or_initialize_by_facebook_id(params[:facebook_id])
    @current_user.facebook_access_token = params[:facebook_access_token]
    @current_user.first_name = params[:first_name]
    @current_user.last_name = params[:last_name]
    @current_user.full_name = params[:facebook_name]
    @current_user.save
    
    # Generate a random token for this user if this is the first time and setting create_at
    if @current_user.access_token.nil?
      @current_user.update_attribute('access_token', SecureRandom.hex(64))
      @current_user.set_joined_at
    end
    
    # Fetch friends for current user
    # find_friends_for_facebook_id(@current_user.facebook_id, nil)
    
    # The response only local access_token    
    session_response_hash = {:access_token => @current_user.access_token}
    
    respond_to do |format|
      format.xml  { render :xml => session_response_hash.to_xml }
      format.json  { render :json => session_response_hash.to_json }
    end
  end


  # API for registering a user's device for pushing
  # :access_token
  # :device_token
  # http://orcapods.heroku.com/v1/registerpush?access_token=893d80135f5128349a89a4915be15fd442cc6e4c3dd63e7bedc1213645cb554827a774fddaac4918e19ad0511f026de7671d22f101033dbbb61062ba0e168377
  def registerpush
    response = {:success => "false"}
    @current_user = User.find_by_access_token(params[:access_token])
    if @current_user.nil?
      response = {:success => "false"}
    else
      @current_user.update_attribute('device_token', params[:device_token].to_s)
      response = {:success => "true"}
    end
    
    respond_to do |format|
      format.xml  { render :xml => response.to_xml }
      format.json  { render :json => response.to_json }
    end
    
  end
  
  # This API registers a new session from a client
  # Receives a GET with access_token from the user
  # This will fire since calls for the current user
  # http://localhost:3000/v1/session?access_token=9567517e6574115fbb23db2753dce581c6f3df08e60251bd7693236158c6801a432ed65d072b3487eb78107bf425a1de2025ad0e08e7da8e1381a2a2bcb2e6f9
  def session
    @current_user = User.find_by_access_token(params[:access_token])
        
    # Fetch content for current user
    find_friends_for_facebook_id(@current_user.facebook_id, since = nil)
    
    # return new friends
    # We want to send the entire friendslist hash of id, name to the client
    # friend_array = Friendship.find(:all, :select=>"friend_id, friend_name", :conditions=>"user_id = #{@current_user.id}").map {|f| {:friend_id=>f.friend_id.to_i, :friend_name=>f.friend_name}}
    # friend_id_array = friend_array.map  do |f| f[:friend_id] end
    #   
    # # The response should include the current user ID and name for the client to cache
    # session_response_hash = {
    #   :access_token => @current_user.access_token,
    #   :facebook_id => @current_user.facebook_id,
    #   :name => @current_user.name,
    #   :friends => friend_array
    # }
    
    session_response_hash = {
      :access_token => @current_user.access_token
    }

    respond_to do |format|
      format.xml  { render :xml => session_response_hash.to_xml }
      format.json  { render :json => session_response_hash.to_json }
    end
  end
  
  # Finds friends for a single facebook id
  # https://graph.facebook.com/me/friends?fields=third_party_id,first_name,last_name,name,gender,locale&access_token=???
  # find_friends_for_facebook_id()
  def find_friends_for_facebook_id(facebook_id = nil, since = nil)
    if facebook_id.nil? then facebook_id = @@james_id end

    puts "START find friends for facebook_id: #{facebook_id}"

    headers_hash = Hash.new
    headers_hash['Accept'] = 'application/json'

    params_hash = Hash.new
    params_hash['access_token'] = @current_user.facebook_access_token
    params_hash['fields'] = 'third_party_id,first_name,last_name,name,gender,locale'

    if !since.nil? then
      params_hash['since'] = since.to_i
    end

    # http://graph.facebook.com/645750651/friends?access_token132514440148709%257Cf09dd88ba268a8727e4f3fd5-645750651%257Ck21j0yXPGxYGbJPd0eOEMTy5ZN4
    response = Typhoeus::Request.get("#{@@fb_host}/#{facebook_id}/friends", :params => params_hash, :headers => headers_hash, :disable_ssl_peer_verification => true)

    parsed_response = self.check_facebook_response_for_errors(response)
    if parsed_response.nil?
      return false
    end

    friend_id_array = Array.new

    # Bulk serialize friends
    friend_id_array = self.serialize_friend_bulk(parsed_response['data'],facebook_id,1)

    # Update last_fetched_friends timestamp for user
    # self.update_last_fetched_friends(facebook_id)

    puts "END find friends for facebook_id: #{facebook_id}"

    return true
  end
  
  def serialize_friend_bulk(friends, facebook_id, degree)
      create_new_user = []
      create_new_friend = []
      friend_id_array = []
      friends.each do |friend|
        # New, faster way of bulk inserting in database
        # Create new user
        user_facebook_id = friend['id']
        # third_party_id = friend['third_party_id']
        # picture_url = "https://graph.facebook.com/#{friend['id']}/picture"
        name = friend.has_key?('name') ? friend['name'] : nil
        first_name = friend.has_key?('first_name') ? friend['first_name'] : nil
        last_name = friend.has_key?('last_name') ? friend['last_name'] : nil
        # locale = friend.has_key?('locale') ? friend['locale'] : nil
        # verified = friend.has_key?('verified') ? friend['verified'] : nil

        create_new_user << [user_facebook_id, name, first_name, last_name]
        create_new_friend << [facebook_id, friend['id'], friend['name']]
        friend_id_array << friend['id']
      end

      user_columns = [:facebook_id, :full_name, :first_name, :last_name]
      friend_columns = [:user_id, :friend_id, :friend_name]

      User.import user_columns, create_new_user, :on_duplicate_key_update => [:name]
      # Friendship.import friend_columns, create_new_friend, :on_duplicate_key_update => [:friend_name]
      
      friend_id_array_string = friend_id_array.join(',') 
      query = " insert ignore into friendships
                (user_id, friend_id, friend_name)
                select a.id, b.id, b.name
                from users a
                join users b on b.facebook_id in (#{friend_id_array_string})
                where a.facebook_id = #{facebook_id}
              "
      mysqlresult = ActiveRecord::Base.connection.execute(query)

      return friend_id_array
    end
    
    def check_facebook_response_for_errors(response = nil)
         # If the response is nil, we error out
        if response.body.nil?
          Rails.logger.info "\n\n======\n\nEmpty Response From Facebook\n\n=======\n\n"
          return nil
        end

        # puts "\n\n======\n\nPrinting raw response: #{response.body}\n\n=======\n\n"

        # parse the json response
        parsed_response = JSON.parse(response.body)

        # read generic error
        if (!parsed_response["error_code"].nil?) || (!parsed_response["error_msg"].nil?)
          Rails.logger.info "\n\n======\n\nFacebook Generic Error Code: #{parsed_response["error_code"]}, Message: #{parsed_response["error_msg"]}\n\n=======\n\n"
          return nil
        end

        # read oauth error
        if (!parsed_response["error"].nil?)
          error_type = parsed_response["error"]["type"]
          error_message = parsed_response["error"]["message"]

          # We got throttled, respond with error
          # Maybe in the future we can queue the request in a delayed job?
          if (error_type == "OAuthException" && error_message == "(#613) Calls to checkin_fql have exceeded the rate of 600 calls per 600 seconds.")
            Rails.logger.info "\n\n======\n\nWe got THROTTLED by Facebook!!!\n\n=======\n\n"
          elsif (error_type == "OAuthException" && error_message == "Error validating access token.")
            Rails.logger.info "\n\n======\n\nWe got an invalid token: #{@access_token}!!!\n\n=======\n\n"
          else
            Rails.logger.info "\n\n======\n\nFacebook Error Caught: #{parsed_response["error"]}\n\n=======\n\n"
          end
          return nil
        end

        return parsed_response
    end
  
end