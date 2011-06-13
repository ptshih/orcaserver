require 'OrcaWorker'
require 'Sequel'
# => Pod(id: integer, name: string, last_message_id: integer, created_at: datetime, updated_at: datetime) 

# Pod.async(:create_message,id,arg1,arg2) will result in
# Pod.find(id).create_message(arg1,arg) on the worker box

class Pod < OrcaWorkerModel
  
  @DB = Sequel.connect(:adapter=>'mysql2', :host=>'localhost', :database=>'orca',
    :user=>'root', :password=>'')
  
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
      SELECT * FROM PODS
      WHERE (SELECT POD_ID FROM PODS_USERS WHERE USER_ID=#{user_id})
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
  
  def self.message_index(pod_id)
    response_array = []
    query = "
        SELECT hashid, message, updated_at FROM MESSAGES
        WHERE pod_id = #{pod_id}
        ORDER BY UPDATED_AT DESC
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
  
  def self.async_create_message(pod_id, user_id, hashid, message)
    Pod.async(:create_message,pod_id, user_id, hashid, message)
  end

  def self.create(user_id, name)
    insert_response = @DB[" INSERT INTO pods (name, created_at, updated_at)
          VALUES (?,now(),now())", name]
    response = "Created the pod with id = #{insert_response.insert.to_s}"

    insert_response = @DB[" INSERT INTO pods_users (pod_id, user_id)
          VALUES (?,?)", insert_response.insert.to_i, user_id.to_i]
    
    return response
  end
  
  def self.create_message(pod_id, user_id, hashid, message)

    insert_response = @DB[" INSERT INTO messages (pod_id, user_id, hashid, message, created_at, updated_at)
          VALUES (?,?,?,?,now(),now())", pod_id, user_id, hashid, message]
    response = "Created the message with id = #{insert_response.insert.to_s}"
    return response
  end

  
end