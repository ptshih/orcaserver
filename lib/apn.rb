require 'openssl'
require "socket"
require 'json'
require 'benchmark'
require 'resque'

class OrcaAPN
  def initialize
    cert = File.read('/home/bitnami/orcapods/ck.pem')
    @ctx = OpenSSL::SSL::SSLContext.new
    @ctx.key = OpenSSL::PKey::RSA.new(cert, 'orca') #set passphrase here, if any
    @ctx.cert = OpenSSL::X509::Certificate.new(cert)
    reconnect
  end
  def reconnect
    puts 'connecting to gateway.sandbox.push.apple.com:2195'
    @sock = TCPSocket.new('gateway.sandbox.push.apple.com', 2195) #development gateway
    @ssl = OpenSSL::SSL::SSLSocket.new(@sock, @ctx)
    @ssl.connect
  end
  def close
    @ssl.close
    @sock.close
  end
  def push(token,message,json,badge)
      payload = {"aps" => {"alert" => message, "badge" => badge, "sound" => 'default'},'message'=>json.to_json}
      json = payload.to_json()
      token =  [token.delete(' ')].pack('H*')
    begin
      @ssl.write("\0\0 #{token}\0#{json.length.chr}#{json}")
    rescue => e
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
        puts job.inspect
        args = job['args']
        $apn.push(args[2],args[3],args[4],args[5])
      else
        break
      end
    end
  rescue => e
    puts e
    # put job back on queue while apns reconnects
    job.recreate
  end
  sleep 0.5
end

# require 'apn.rb'
# def pushToiOSDevice(token,message,json,badge)
#   # if this happens to be running within a push queue worker
#   # if there is no apn connection open, open one
#   if $apn.nil? && ENV['QUEUE']=='pushQueue'
#     puts 'starting up $apn'
#     $apn = OrcaAPN.new
#   end
# 
#   if $apn
#     puts "pushing msg to #{token}"
#     $apn.push(token,message,json,badge)
#   else
#     raise "apple push notification service not available! was this job pushed to the pushQueue? ENV['QUEUE']=#{ENV['QUEUE']}"
#   end
# end
# 
# 
# thred1 = Thread.new {
#   apn = OrcaAPN.new
#   50.times do |i|
#     time = Benchmark.measure do
#       apn.push('1d2301b234494ed1df0b6bfc848840543b5fa45afec8f402a7b7a493b8195464',"sock 1 - #{i} - yo what up",{:code=>{:nest=>[1,2,3]}},0)
#       sleep 0.05
#     end
#   end
# }
# 
# # thred1.resume
# 
# thread2 = Thread.new {
#   apn2 = OrcaAPN.new
#   50.times do |i|
#     time = Benchmark.measure do
#       apn2.push('1d2301b234494ed1df0b6bfc848840543b5fa45afec8f402a7b7a493b8195464',"sock 2 - #{i} - yo what up",{:code=>{:nest=>[1,2,3]}},0)
#       sleep 0.05
#     end
#   end
# }
# # thread2.resume
# sleep 5

