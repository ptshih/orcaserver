require 'OrcaWorker'

class User < ActiveRecord::Base
  @queue = :pushQueue

  # this writes a job into the orca workers box
  def self.pushMessageToUser(user_id,message,json,badge)
    token = User.find(user_id)['device_token']
    if token
      User.async(:pushMessage,user_id,token,message,json,badge)
    else
      Rails.logger.info "tried to send push to a user without token userid #{user_id}"
    end
  end
  
  def set_joined_at
      now_time = Time.now.utc.to_s(:db)
      query = " update users
                set joined_at = '#{now_time}'
                where facebook_id = #{self.facebook_id} and joined_at is null
              "
      mysqlresult = ActiveRecord::Base.connection.execute(query)

  end
  
  def add_to_party_pod
    pod_id = 1
    now_time = Time.now.utc.to_s(:db)
    query = " insert ignore into pods_users
              (user_id, pod_id, updated_at, created_at)
              select #{self.id}, #{pod_id}, '#{now_time}', '#{now_time}'"
    mysqlresult = ActiveRecord::Base.connection.execute(query)
    
    query = " select * from pods_users where user_id = #{self.id} and created_at = '#{now_time}'"
    mysqlresult = ActiveRecord::Base.connection.execute(query)

    if mysqlresult['Rows']>0
      message_sequence = SecureRandom.hex(64)
      joined_pod=Pod.find_by_id(pod_id)
      message = " joined pod #{joined_pod.name}"
      Pod.async_create_message(pod_id, self.id, self.get_short_name, message_sequence, message)
    end
    
  end
  
  # "John Smith" becomes "John S"
  def get_short_name
    user_name = ""
    if !self.first_name.nil?
      user_name = self.first_name
    end
    if self.last_name.length>1
      user_name = user_name + " " + self.last_name[0]
    end
    return user_name
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