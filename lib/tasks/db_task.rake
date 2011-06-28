require 'json'
require 'rubygems'

namespace :db_task do

  desc "rake task creating metadata from message attributes, if metadata doesn't already exist"
  task :create_message_metadata => :environment do
    
    query = "select * from messages limit 10"
    qresult = ActiveRecord::Base.connection.execute(query)
    
    qresult.each(:as => :hash) do |row|
      puts row
      
      if row['metadata'].nil?
        
        # insert code that creates metadata
        metadata_hash['photo_width'] = row['photo_width']
        metadata_hash['photo_height'] = row['photo_height']
        metadata_hash['photo_url'] = row['photo_url']
        metadata = JSON.generate metadata_hash
        
        # update the column value
        query = "update messages set metadata = #{metadata} where id = #{row['id']}"
        ActiveRecord::Base.connection.execute(query)
        
      end
      
    end
  
  end # end task


end # end namespace