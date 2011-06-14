class ApplicationController < ActionController::Base
  # protect_from_forgery
  
  def load_version(valid_versions = ["v1","v2","v3"])
    @version =  params[:version]
    if !valid_versions.include?(@version)
      error_response = {}
      error_response["error_type"] = "APIException"
      error_response["error_message"] = "Unknown API Version"
      render :json => error_response, :status => :unauthorized
    end
    
    # render_status("Error:  Invalid Version") and return false unless valid_versions.include?(@version)
  end
  
  def authenticate_token
    
    #  authenticate current user
    if params[:access_token].nil?
      @current_user = User.first
    else
      @current_user = User.find_by_access_token(params[:access_token])
    end
    #  # authenticate current user
    #  if !params[:access_token].nil?
    #    @current_user = User.find_by_id(params[:access_token])
    # 
    #    # check @current_user is not nil
    #    if @current_user.nil?
    #      error_response = {}
    #      error_response["error_type"] = "AuthException"
    #      error_response["error_message"] = "Unauthorized Token #{params[:access_token]}"
    #      render :json => error_response, :status => :unauthorized
    #    else
    #      # load_facebook_api(@current_user.facebook_access_token)
    #    end
    # else
    #    # error_response = {}
    #    # error_response["error_type"] = "AuthException"
    #    # error_response["error_message"] = "Unauthorized Nil Token"
    #    # render :json => error_response, :status => :unauthorized
    #  end
   end
   
   
end
