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
      SELECT p.id, p.name, m.message, u.id as userid, u.facebook_id, u.full_name, p.updated_at
      FROM pods p
      JOIN messages m on p.last_message_id = m.id
      JOIN users u on u.id = m.user_id
      WHERE p.id in (SELECT pod_id FROM pods_users WHERE user_id=#{user_id})
    "
    qresult = ActiveRecord::Base.connection.execute(query)
    qresult.each(:as => :hash) do |row|
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
        SELECT m.id, pod_id, hashid, u.id as userid, u.facebook_id, u.full_name, message, m.updated_at
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


  def self.create(user_id, hashid, name)
    
    query = "
      INSERT INTO pods (name, hashid created_at, updated_at)
      VALUES (\'#{name.gsub(/\\|'/) { |c| "\\#{c}" }}\', \'#{hashid}\', now(), now())
    "

    # insert_response = @DB[query]
    # response = "Created the pod with id = #{insert_response.insert.to_s}"

    qresult = ActiveRecord::Base.connection.execute(query)

    query = "
      INSERT INTO pods_users (pod_id, user_id)
      SELECT id, #{user_id.to_i} FROM pods WHERE hashid=#{hashid})
    "

    # insert_response = @DB[query]

    qresult = ActiveRecord::Base.connection.execute(query)
    
    return nil
  end
  
  def self.async_create_message(pod_id, user_id, current_user_name, hashid, message)
    Pod.async(:create_message,pod_id, user_id, current_user_name, hashid, message)
    return ""
  end
  
  def self.create_message(pod_id, user_id, current_user_name, hashid, message)

    query = "
      INSERT INTO messages (pod_id, user_id, hashid, message, created_at, updated_at)
            VALUES (#{pod_id}, #{user_id}, \'#{hashid}\', \'#{message.gsub(/\\|'/) { |c| "\\#{c}" }}\', now(), now())
    "
    
    # insert_response = @DB[query]
    # response = "Created the message with id = #{insert_response.insert.to_s}"

    qresult = ActiveRecord::Base.connection.execute(query)
    
    query = "
      UPDATE pods p, (select id, created_at from messages where hashid = \'#{hashid}\') m
      SET p.last_message_id = m.id, p.created_at = m.created_at
      WHERE p.id=#{pod_id}
    "
    qresult = ActiveRecord::Base.connection.execute(query)
    
    queryreceivers = "
      select distinct user_id from pods_users map
      join users u on u.id = map.user_id
      where map.pod_id = #{pod_id}
        and u.device_token is not null
        and map.user_id != #{user_id}
        
    "
    # queryreceivers = "
    #   select distinct device_token
    #   from users
    #   where device_token is not null
    #   and id in (select user_id from pods_users where pod_id = #{pod_id})
    #   and id != #{user_id}
    # "
    
    receivers = ActiveRecord::Base.connection.execute(queryreceivers)
    # Do not send push if you are the only user
    # or if other users have no token
    if !receivers.nil?
      receivers.each(:as => :hash) do |row|
        message = current_user_name + ": "+ message
        if message.length >= 30
          message = message[0...30]+"..."
        end
        
        msg = {
          :pod_id  => pod_id,
          :hashid  => hashid,
          :user_id => user_id,
          :updated_at => Time.now.to_i
        }

        if row['user_id'].nil?
          User.pushMessageToUser(User.first.id,message,msg,1)
        else
          User.pushMessageToUser(row['user_id'],message,msg,1)
        end
      end
    end
    

    return nil
  end

  
end