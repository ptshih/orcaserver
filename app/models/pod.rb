require 'OrcaWorker'
require 'Sequel'
# => Pod(id: integer, name: string, last_message_id: integer, created_at: datetime, updated_at: datetime) 

# Pod.async(:create_message,id,arg1,arg2) will result in
# Pod.find(id).create_message(arg1,arg) on the worker box

class Pod < ActiveRecord::Base
  
  @DB = Sequel.connect(:adapter=>'mysql2', :host=>'localhost', :database=>'orca',
    :user=>'root', :password=>'')
  
  def self.all
    
    # Using ActiveRecord
    # query = "select * from pods"
    # mysqlresults = ActiveRecord::Base.connection.execute(query)
    # 
    # mysqlresults.each(:as => :hash) do |row|
    #   response_hash = {
    #     :id => row['id'],
    #     :name => row['name'],
    #     :last_message_id => row['last_message_id'],
    #     :created_at => row['created_at'],
    #     :updated_at => row['updated_at']
    #   }
    #   response_array << response_hash
    # end
    response_array = []
    @DB.fetch("SELECT * FROM pods") do |row|
      response_array << row
    end
    
    return response_array
  end
  
  def self.index(user_id)
    
    query = "
      SELECT * FROM PODS
      WHERE (SELECT POD_ID FROM PODS_USERS WHERE USER_ID=#{user_id})
    "
    @DB.fetch(query) do |row|
      response_array << row
    end
    
  end
  
  def self.message_index(pod_id)
    
    query = "
        SELECT hash_id, message, updated_at FROM MESSAGES
        WHERE pod_id = #{pod_id}
        ORDER BY UPDATED_AT DESC
      "
      @DB.fetch(query) do |row|
        response_array << row
      end
    
  end
  
  def self.async_create_message(pod_id, user_id, hashid, message)
    Pod.async(:create_message,pod_id, user_id, hashid, message)
  end
  
  def self.create_message(pod_id, user_id, hashid, message)

    insert_response = @DB[" INSERT INTO messages (pod_id, user_id, hashid, message, created_at, updated_at)
          VALUES (?,?,?,?,now(),now())", pod_id, user_id, hashid, message]
    resposne = "Created the message with id = #{insert_response.insert.to_s}"
    return resposne
  end

  
end