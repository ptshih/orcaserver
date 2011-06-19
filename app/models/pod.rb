require 'OrcaWorker'
# require 'Sequel'
# => Pod(id: integer, name: string, last_message_id: integer, created_at: datetime, updated_at: datetime) 

# Pod.async(:create_message,id,arg1,arg2) will result in
# Pod.find(id).create_message(arg1,arg) on the worker box

class Pod < ActiveRecord::Base
  @queue = :orcaworker
    
  # @DB = Sequel.connect(:adapter=>'mysql2', :host=>'localhost', :database=>'orca',
  #     :user=>'root', :password=>'')
  
  def self.all
    response_array = []    
    # Using ActiveRecord
    query = "select * from pods"
    qresult = ActiveRecord::Base.connection.execute(query)
    qresult.each(:as => :hash) do |row|
      response_array << row
    end
    # @DB.fetch("SELECT * FROM pods") do |row|
    #   response_array << row
    # end
    return response_array
  end
  
  def self.index(user_id)
    response_array = []
    
    query = "
      select pod_id, first_name
      from pods_users map
      join users u on map.user_id = u.id
      where pod_id in (select pod_id from pods_users where user_id=?)
      and pod_id !=1
    "
    query = sanitize_sql_array([query, user_id])
    qresult = ActiveRecord::Base.connection.execute(query)
    participants_hash = {}
    qresult.each(:as => :hash) do |row|
      if participants_hash[row['pod_id']].nil?
        new_list = [row['first_name']]
        participants_hash[row['pod_id']] = new_list
      else
        participants_hash[row['pod_id']] << row['first_name']
      end
    end 
    
    participants_hash[1] = ['Public Room']
    
    query = "
      SELECT p.id, p.name, m.message, m.hashid, u.id as userid, u.facebook_id, u.full_name, p.updated_at
      FROM pods p
      JOIN messages m on p.last_message_id = m.id
      JOIN users u on u.id = m.user_id
      WHERE p.id in (SELECT pod_id FROM pods_users WHERE user_id=?)
    "
    query = sanitize_sql_array([query, user_id])
    qresult = ActiveRecord::Base.connection.execute(query)
    qresult.each(:as => :hash) do |row|
      participants_string = participants_hash[row['id']][0..2].join(',')
      if participants_hash[row['id']].length>3
        participants_string = participants_string + " and #{participants_hash[row['id']].length-3} more"
      end
      row['participants'] = participants_string
      response_array << row
    end
    # @DB.fetch(query) do |row|
    #   response_array << row
    # end
    return response_array
  end
  
  def self.message_index(pod_id, user_id)
    response_array = []
    query = "
        SELECT m.id, pod_id, hashid, u.id as userid, u.facebook_id, u.full_name,
          m.message, m.has_photo, m.photo_width, m.photo_height, m.hashid,
          m.updated_at
        FROM messages m
        join users u on u.id = m.user_id
        WHERE pod_id = #{pod_id}
        ORDER BY updated_at DESC
    "
    qresult = ActiveRecord::Base.connection.execute(query)
    qresult.each(:as => :hash) do |row|
      response_array << row
    end
    # @DB.fetch(query) do |row|
    #       response_array << row
    #     end
    return response_array    
  end
  
  def self.get_members(pod_id=nil)
    response_array = []
    query = "
        select u.id, u.full_name, u.first_name, u.last_name
        from orca.pods_users map
        join orca.users u on map.user_id = u.id
        where map.pod_id = #{pod_id}
    "
    qresult = ActiveRecord::Base.connection.execute(query)
    qresult.each(:as => :hash) do |row|
      response_array << row
    end
    return response_array
  end


  # Create pod
  # Insert user to pods_users map
  # Create first message of pod
  # def self.create(user_id, hashid, name)
  #   
  #   query = "
  #     INSERT INTO pods (name, hashid, created_at, updated_at)
  #     VALUES (\'#{name.gsub(/\\|'/) { |c| "\\#{c}" }}\', \'#{hashid}\', now(), now())
  #   "
  #   qresult = ActiveRecord::Base.connection.execute(query)
  #   
  #   newpod = Pod.find_by_hashid('#{hashid}')
  #   
  #   query = "
  #     INSERT INTO pods_users (pod_id, user_id)
  #     SELECT #{newpod.id}, #{user_id.to_i}
  #   "
  #   qresult = ActiveRecord::Base.connection.execute(query)
  # 
  #   message = "created pod"
  #   send_name = newpod.name
  #   async_create_message(newpod_id, user_id, send_name, hashid, message)
  #   
  #   return newpod
  # 
  # end
  
  
  # params[:has_photo], params[:photo_width], params[:photo_height], params[:metadata], params[:lat], params[:lng])
  def self.async_create_message(pod_id, user_id, current_user_name, hashid, message,
      has_photo=nil, photo_width=nil, photo_height=nil, metadata=nil, lat=nil, lng=nil)
    Pod.async(:create_message,pod_id, user_id, current_user_name, hashid, message, has_photo,
      photo_width, photo_height, metadata, lat, lng)
    return ""
  end
  
  def self.create_message(pod_id, user_id, current_user_name, hashid, message,
      has_photo=nil, photo_width=nil, photo_height=nil, metadata=nil, lat=nil, lng=nil)

    created_at = Time.now.utc.to_s(:db)
    updated_at = Time.now.utc.to_s(:db)    
    # query = "
    #   INSERT INTO messages (pod_id, user_id, hashid, message, created_at, updated_at)
    #         VALUES (#{pod_id}, #{user_id}, \'#{hashid}\', \'#{message.gsub(/\\|'/) { |c| "\\#{c}" }}\', now(), now())
    # "
    query = "
      INSERT INTO messages (pod_id, user_id, hashid, message, has_photo, photo_width, photo_height, metadata, lat, lng, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    "
    query = sanitize_sql_array([query, pod_id, user_id, hashid, message,
        has_photo, photo_width, photo_height, metadata, lat, lng, created_at, updated_at])
    qresult = ActiveRecord::Base.connection.execute(query)
    
    query = "
      UPDATE pods p, (select id, created_at from messages where hashid = ?) m
      SET p.last_message_id = m.id, p.updated_at = m.created_at
      WHERE p.id=?
    "
    query = sanitize_sql_array([query, hashid, pod_id])
    qresult = ActiveRecord::Base.connection.execute(query)
    now_time = Time.now.utc.to_s(:db)
    queryreceivers = "
      select distinct user_id
      from pods_users map
      join users u on u.id = map.user_id
      where map.pod_id = #{pod_id}
        and u.device_token is not null
        and map.user_id != #{user_id}
        and (map.mute_until is null or map.mute_until<='#{now_time}')
    "
    receivers = ActiveRecord::Base.connection.execute(queryreceivers)
    # Do not send push if you are the only user
    # or if other users have no token
    if !receivers.nil?
      
      receivers.each(:as => :hash) do |row|
        user_message = current_user_name + ": "+ message
        if user_message.length >= 30
          user_message = user_message[0...30]+"..."
        end
        
        msg = {
          :pod_id  => pod_id,
          :hashid  => hashid,
          :user_id => user_id,
          :updated_at => Time.now.to_i
        }

        if row['user_id'].nil?
          User.pushMessageToUser(User.find_by_id(1),user_message,msg,0)
        else
          User.pushMessageToUser(row['user_id'],user_message,msg,0)
        end
      end
    end

    return ""
  end

  # Add the user to pods_users mapping
  # If user already part of pod, return false, Else true
  def add_user_to_pod(target_user_id=nil, user_id=nil)
    
    now_time = Time.now.utc.to_s(:db)
    query = " insert ignore into pods_users
              (user_id, pod_id, updated_at, created_at)
              select #{target_user_id}, #{self.id}, '#{now_time}', '#{now_time}'"
    mysqlresult = ActiveRecord::Base.connection.execute(query)
    
    query = " select count(*) as rows from pods_users where user_id = #{target_user_id} and created_at = '#{now_time}'"
    mysqlresult = ActiveRecord::Base.connection.execute(query)
    rowcount=0
    mysqlresult.each(:as => :hash) do |row|
      rowcount=row['rows']
    end
    
    added_user = User.find_by_id(target_user_id)
    user = User.find_by_id(user_id)    

    # when user has joined pod, add message to pod stating the join
    if rowcount>0
      message_sequence = SecureRandom.hex(64)
      message = "added #{added_user.full_name} to pod #{self.name}"
      Pod.async_create_message(self.id, user_id, user.get_short_name, message_sequence, message)
      return true
    end
    
    return false
    
  end
  
  # Remove user from pods_users mapping
  def remove_user_from_pod(target_user_id=nil, user_id=nil)
    
    now_time = Time.now.utc.to_s(:db)
    query = " delete from pods_users
              where user_id = #{target_user_id} and pod_id = #{self.id}
            "
    mysqlresult = ActiveRecord::Base.connection.execute(query)

    target_user = User.find_by_id(target_user_id)
    user = User.find_by_id(user_id)

    # when user has left the pod, add message to pod stating the remove
    message_sequence = SecureRandom.hex(64)
    message = "removed #{target_user.full_name} from pod"
    Pod.async_create_message(self.id, user_id, user.get_short_name, message_sequence, message)
    return true
    
  end
  
end