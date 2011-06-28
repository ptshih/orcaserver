require 'OrcaWorker'

class Log < ActiveRecord::Base
  @queue = :orcaworker
  
  def self.async_logging(event_timestamp, udid, device_model, user_id, lat, lng, action_type)
    Log.async(:logging,event_timestamp, udid, device_model, user_id, lat, lng, action_type)
    return ""
  end
  
  def self.logging(event_timestamp, udid, device_model, user_id, lat, lng, action_type)
    
    query = "
      INSERT INTO logs (event_timestamp, udid, device_model, user_id, lat, lng, action_type)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    "
    query = sanitize_sql_array([query, event_timestamp, udid, device_model, user_id, lat, lng, action_type])
    qresult = ActiveRecord::Base.connection.execute(query)
    
    # CREATE TABLE `logs` (
    #       `id` int(11) NOT NULL AUTO_INCREMENT,
    #       `event_timestamp` datetime NOT NULL,
    #       `session_starttime` datetime NOT NULL,
    #       `udid` varchar(55) COLLATE utf8_unicode_ci DEFAULT NULL,
    #       `device_model` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
    #       `system_name` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
    #       `system_version` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
    #       `app_version` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
    #       `user_id` bigint(20) DEFAULT NULL,
    #       `connection_type` int(11) DEFAULT NULL,
    #       `language` varchar(15) COLLATE utf8_unicode_ci DEFAULT NULL,
    #       `locale` varchar(15) COLLATE utf8_unicode_ci DEFAULT NULL,
    #       `lat` decimal(20,16) DEFAULT NULL,
    #       `lng` decimal(20,16) DEFAULT NULL,
    #       `action_type` varchar(30) COLLATE utf8_unicode_ci DEFAULT NULL,
    #       `var1` decimal(16,8) DEFAULT NULL,
    #       `var2` bigint(20) DEFAULT NULL,
    #       `var3` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
    #       `var4` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
    #       PRIMARY KEY (`id`)
    #     ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci
    
  end
  
end