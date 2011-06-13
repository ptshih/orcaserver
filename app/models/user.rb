require 'OrcaWorker'
require 'apn.rb'

class User < ActiveRecord::Base
  @queue = :pushQueue
  
  def self.pushMessage(user_id,token,message,json,badge)
    # unscalable way for now...
    OrcaAPN.new.push(token,message,json,badge)
  end

  def self.pushMessageToUser(user_id,message,json,badge)
    token = User.find(user_id)['device_token']
    if token
      User.async(:pushMessage,user_id,token,message,json,badge)
    end
  end
  
  # def initialize(facebook_id)
  #   
  #   query = "
  #     SELECT * FROM USERS WHERE facebook_id = #{facebook_id}
  #   "
  #   response = ActiveRecord::Base.connection.execute(query)
  #   response.each(:as => :hash) do |row|
  #     user = row
  #   end
  #   
  #   return user
  # end
  # 
  # def self.find_by_access_token(access_token)
  #   query = "
  #     SELECT * FROM USERS WHERE id = #{access_token}
  #   "
  #   response = ActiveRecord::Base.connection.execute(query)
  #   user = nil
  #   response.each(:as => :hash) do |row|
  #     user = row
  #   end
  #   return user
  # end
  # 
  # def create(facebook_id, facebook_accesstoken=nil, apns_token=nil, last_message_hashid=nil)
  #   
  #   query = "
  #     INSERT INTO USERS (facebook_id)
  #     VALUES(#{facebook_id})
  #   "
  #   response = ActiveRecord::Base.connection.execute(query)
  #   
  #   return User.initialize(facebook_id)
  #   
  # end

end