require 'json'

class Diffbot < ActiveRecord::Base
  
  def self.create (hash_values)
    # title, pubdate, link, guid, description, enclosure
    # Time.now.utc.to_s(:db)
    mytime = ''
    if !hash_values['pubDate'].nil?
      mytime = Time.parse(hash_values['pubDate'])
    end
    query = "
      insert into diffbots
      (title, pubdate, link, guid, description, enclosure, metadata, updated_at)
      select ?, ?, ?, ?, ?, ?, ?, now()
    "
    metadata = JSON.generate hash_values
    query = sanitize_sql_array([query, hash_values['title'], mytime, hash_values['link'], hash_values['guid'], hash_values['description'], metadata, hash_values['enclosure']])
    qresult = ActiveRecord::Base.connection.execute(query)
    
    
  end
  
end