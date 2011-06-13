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
      SELECT * FROM pods
      WHERE id in (SELECT pod_id FROM pods_users WHERE user_id=#{user_id})
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
        SELECT hashid, message, updated_at FROM messages
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


  def self.create(hashid, name)
    
    query = "
      INSERT INTO pods (name, hashid created_at, updated_at)
      VALUES (\'#{name}\', \'#{hashid}\', now(), now())
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
    
    return response
  end
  
  def self.async_create_message(pod_id, user_id, hashid, message)
    Pod.async(:create_message,pod_id, user_id, hashid, message)
    return ""
  end
  
  def self.create_message(pod_id, user_id, hashid, message)

    query = "
      INSERT INTO messages (pod_id, user_id, hashid, message, created_at, updated_at)
            VALUES (#{pod_id}, #{user_id}, \'#{hashid}\', \'#{message}\', now(), now())
    "
    
    # insert_response = @DB[query]
    # response = "Created the message with id = #{insert_response.insert.to_s}"

    qresult = ActiveRecord::Base.connection.execute(query)
    response = ""

    return response
  end

  
end