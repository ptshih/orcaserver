require 'json'
require 'rubygems'
require 'typhoeus'
require 'json'

class Article < ActiveRecord::Base
  
  @access_token = '965862e81bea448ffa44d8c902195820'
  
  def self.fetch_diffbot_article(url=nil)
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
      
      title = parsed_response['title']
      url = parsed_response['url']
      v_md5 = Digest::MD5.hexdigest(url)
      summary = parsed_response['summary']
      author = parsed_response['author']
      tags = JSON.generate parsed_response['tags']
      text = parsed_response['text']
      created_at = Time.now.utc.to_s(:db)
      updated_at = Time.now.utc.to_s(:db)
      query = "
        insert ignore into articles
        (v_md5, title, url, summary, text, author, tags, created_at, updated_at)
        select ?, ?, ?, ?, ?, ?, ?, ?, ?
      "
      query = sanitize_sql_array([query, v_md5, title, url, summary, text, author, tags, created_at, updated_at])
      qresult = ActiveRecord::Base.connection.execute(query)
      
    end
    
  end
  
end