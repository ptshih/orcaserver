require 'openssl'
require "socket"
require 'json'
require 'benchmark'
require 'resque'
require 'logger'
require 'em-websocket'

$logger = Logger.new('/home/bitnami/log/orcapush.log') rescue nil

$logger.datetime_format = "%Y-%m-%d %H:%M:%S"

def log(o)
  $logger.info(o)
end

EventMachine.run {
  @channel = EM::Channel.new
  EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8282, :debug => true) do |ws|
    ws.onopen {
      sid = @channel.subscribe { |msg| ws.send msg }
      @channel.push "#{sid} connected!"
      ws.onmessage { |msg|
        @channel.push "<#{sid}>: #{msg}"
      }
      ws.onclose {
        @channel.unsubscribe(sid)
      }
    }
  end
  puts "Websocket Server started on :8282"
}

class OrcaAPN
  def initialize
    cert = File.read('/home/bitnami/orcapods/ck.pem')
    @ctx = OpenSSL::SSL::SSLContext.new
    @ctx.key = OpenSSL::PKey::RSA.new(cert, 'orca') #set passphrase here, if any
    @ctx.cert = OpenSSL::X509::Certificate.new(cert)
    reconnect
  end
  def reconnect
    log 'connecting to gateway.sandbox.push.apple.com:2195'
    @sock = TCPSocket.new('gateway.sandbox.push.apple.com', 2195) #development gateway
    @ssl = OpenSSL::SSL::SSLSocket.new(@sock, @ctx)
    @ssl.connect
  end
  def close
    @ssl.close
    @sock.close
  end
  def push(token,message,json,badge)
      # "badge" => badge,
      payload = {"aps" => {"alert" => message, "sound" => 'default'},'message'=>json.to_json}
      json = payload.to_json()
      token =  [token.delete(' ')].pack('H*')
      
      @channel.push(json) rescue nil
    begin
      @ssl.write("\0\0 #{token}\0#{json.length.chr}#{json}")
    rescue => e
      log "#{e.to_s} \n #{e.backtrace}"
      reconnect
      raise e
    end
  end
end
# {"class"=>"User", "args"=>["pushMessage", 391, "1d2301b234494ed1df0b6bfc848840543b5fa45afec8f402a7b7a493b8195464", "yo what is up", {"struct"=>[1, 2, 3]}, 1]}

# 10 msgs, twice a second ~ 20msg/sec for 1 worker 
# 1,728,000 msg/day 

$apn = OrcaAPN.new
while(true)
  job = nil
  begin
    10.times do 
      job = Resque.pop('pushQueue')
      if job 
        log job.inspect
        args = job['args']
        $apn.push(args[2],args[3],args[4],args[5])
      else
        break
      end
      # sleep 0.05
    end
  rescue => e
    log e
    # put job back on queue while apns reconnects
    job.recreate
  end
  sleep 0.5
end