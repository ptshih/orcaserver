require 'json'
require 'rubygems'
require 'typhoeus'
require 'json'

class Article < ActiveRecord::Base
  
  @access_token = '965862e81bea448ffa44d8c902195820'
  
  def fetch_diffbot_article
    url = params[:url]
    if !url.nil?
      headers_hash = Hash.new
      headers_hash['Accept'] = 'application/json'
      phash = Hash.new
      base_url = "http://www.diffbot.com/api/article"
      phash['token'] = @access_token
      phash['url'] = url
      phash['tags'] = ''
      phash['summary'] = ''
      phash['stats'] = ''
      response = Typhoeus::Request.get(base_url, :params => phash, :headers => headers_hash, :disable_ssl_peer_verification => true)
      parsed_response = JSON.parse(response.body)
      
      query = "
        insert into articles
        (v_md5, title, url, summary, text, author, tags)
        select ?, ?, ?, ?, ?, ?, ?
      "
      query = sanitize_sql_array([query, hash_values['title'], mytime, hash_values['link'], hash_values['guid'], hash_values['description'], metadata, hash_values['enclosure']])
      qresult = ActiveRecord::Base.connection.execute(query)
      
      
    end
    
  end
  
end