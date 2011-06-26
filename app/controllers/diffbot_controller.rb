require 'rubygems'
require 'typhoeus'
require 'json'
require 'nokogiri'

class DiffbotController < ApplicationController
  
  @access_token = '965862e81bea448ffa44d8c902195820'
  
  before_filter do |controller|
    # This will set the @version variable
    controller.load_version(["v1","v2","v3"])
  end
  
  # Fetch articles
  # @param REQUIRED url
  # http://localhost:3000/v1/diffbot?url=nytimes.com
  # http://orcapods.heroku.com/v1/diffbot
  def fetch_url

    url = params[:url]
    if !url.nil?
      diffbot_rss_url = "http://www.diffbot.com/api/rss/"+url
    
      response = Typhoeus::Request.get(diffbot_rss_url).body
      @doc = Nokogiri::XML(response)
    
      # Get all "link" from feed
      # @doc.xpath("//link").each do |target_link|
      item_attributes = ['title','pubDate','link','guid','description','enclosure']
      @doc.xpath("//item").each do |item|
      
        # @doc.xpath("//item")[1]
        item_hash = {}
        item.children.each do |item_nodes|
          # @doc.xpath("//item")[1].children.each do |item|; puts item.name; end
          # @doc.xpath("//item")[1].children[1]
          attribute_name = item_nodes.name
          if item_attributes.include?(attribute_name) && !attribute_name.nil?
          
            # Parse link from description
            if attribute_name == 'description'
              doc_html = Nokogiri::HTML(item_nodes.children.text)
              save_link = ''
              doc_html.xpath("//*/a").each do |link|
                  if !link['href'].nil? && save_link ==''
                    save_link = link['href']
                    item_hash['link'] = save_link
                    item_hash['v_md5'] = Digest::MD5.hexdigest(save_link)
                  end
              end
            end
            item_hash[attribute_name] = item_nodes.children.text
          end
        
        end # End loop of item attributes title, pubdate, etc.
      
        # Create diffbot object of 'items'
        Diffbot.create(item_hash)

      end # End loop of items in diffbot rss
      
    end # End url nil check
    response = "hello"
    response = {:success => "True: "+response}
    respond_to do |format|
      format.xml  { render :xml => response }
      format.json  { render :json => response }
    end
    
  end
  
  def fetch_article
    
  end
  
end



# http://www.diffbot.com/api/rss/nytimes.com
# @doc = Nokogiri::XML(Typhoeus::Request.get('http://www.diffbot.com/api/rss/nytimes.com').body)
# @doc.xpath("//link")
# @doc.xpath("//link")[3]
# @doc.xpath("//description")[3]
# @doc.xpath("//description")[3].children
# #  Get the CDATA
# @doc.xpath("//description")[3].children[0].content
# doc_html = Nokogiri::HTML(@doc.xpath("//description")[3].children[0].content)
# doc_html.xpath("//h3/a").map { |link| link['href'] }
