require 'OrcaWorker'

# => Pod(id: integer, name: string, last_message_id: integer, created_at: datetime, updated_at: datetime) 

# Pod.async(:create_message,id,arg1,arg2) will result in
# Pod.find(id).create_message(arg1,arg) on the worker box

class Pod < OrcaWorkerModel
  
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
  
  def self.create_via_resque(pod_id, name)
    Pod.async(:create,{
      :name => name
    })
  end
  
  def self.create_message(pod_id, message_uuid, message)
    Pod.async(:create,pod_id,{})
  end

  
end