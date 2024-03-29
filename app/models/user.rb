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

      # TODO: if new user has joined, alert friends via buddy list (not push)

  end
  
  def mute_pod(pod_id, hours)
    
    now_time = Time.now.utc.to_s(:db)
    # Mute x hours later
    mute_until = (Time.now.utc+60*60*hours).to_s(:db)
    query = "
      update pods_users m
      set mute_until = '#{mute_until}', updated_at = '#{now_time}'
      where m.user_id = #{self.id} and m.pod_id = #{pod_id}
    "
    mysqlresult = ActiveRecord::Base.connection.execute(query)
    
    # TODO: if pod has been muted, send msg to pod from user notifying other's in the pod
    
  end
  
  def add_to_pod(pod_id=nil)
    
    if pod_id.nil?
      pod_id=1
    end
    now_time = Time.now.utc.to_s(:db)
    query = " insert ignore into pods_users
              (user_id, pod_id, updated_at, created_at)
              select #{self.id}, #{pod_id}, '#{now_time}', '#{now_time}'"
    mysqlresult = ActiveRecord::Base.connection.execute(query)
    
    query = " select count(*) as rows from pods_users where user_id = #{self.id} and created_at = '#{now_time}'"
    mysqlresult = ActiveRecord::Base.connection.execute(query)
    rowcount=0
    mysqlresult.each(:as => :hash) do |row|
      rowcount=row['rows']
    end
    
    # when user has joined pod, add message to pod stating the join
    if rowcount>0

      joined_pod=Pod.find_by_id(pod_id)
      params = {}
      params['message'] = " joined pod #{joined_pod.name}"
      params['pod_id'] = pod_id
      params_json = JSON.generate params
      Pod.async_create_message(self.id, self.get_short_name, params_json)
    end
    
  end
  
  # "John Smith" becomes "John S"
  def get_short_name
    user_name = ""
    if !self.first_name.nil?
      user_name = self.first_name.to_s
    end
    if !self.last_name.nil?
      user_name = user_name + " " + self.last_name[0].to_s
    end
    return user_name
  end

end