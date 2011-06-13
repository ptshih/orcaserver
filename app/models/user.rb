class User
  
  def initialize(facebook_id)
    
    query = "
      SELECT * FROM USERS WHERE facebook_id = #{facebook_id}
    "
    response = ActiveRecord::Base.connection.execute(query)
    response.each(:as => :hash) do |row|
      user = row
    end
    
    return user
  end
  
  def create(facebook_id, facebook_accesstoken=nil, apns_token=nil, last_message_hashid=nil)
    
    query = "
      INSERT INTO USERS (facebook_id)
      VALUES(#{facebook_id})
    "
    response = ActiveRecord::Base.connection.execute(query)
    
    return User.initialize(facebook_id)
    
  end

  
end