require 'openssl'
require "socket"
require 'json'
require 'benchmark'

class OrcaAPN
  def initialize
    cert = File.read('/home/bitnami/orcapods/ck.pem')
    @ctx = OpenSSL::SSL::SSLContext.new
    @ctx.key = OpenSSL::PKey::RSA.new(cert, 'orca') #set passphrase here, if any
    @ctx.cert = OpenSSL::X509::Certificate.new(cert)
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
    @ssl.write("\0\0 #{token}\0#{json.length.chr}#{json}")
  end
end
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

