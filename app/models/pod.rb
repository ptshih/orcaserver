class Pod < ActiveRecord::Base
  
  def self.all
    
    response_array = []
    
    query = "select * from pods"
    mysqlresults = ActiveRecord::Base.connection.execute(query)
    
    mysqlresults.each(:as => :hash) do |row|
      response_hash = {
        :id => row['id'],
        :name => row['name'],
        :last_message_id => row['last_message_id'],
        :created_at => row['created_at'],
        :updated_at => row['updated_at']
      }
      response_array << response_hash
    end
    
    return mysqlresults
  end
  
  def self.create_via_resque(pod_id, message_uuid, message)
  
  end
  
  def self.create_message(pod_id, message_uuid, message)
  end
  
end