require 'sinatra'

get '/restart' do
  "<pre>#{%x[sudo chmod 777 /home/bitnami/orcapods/restart.sh;/home/bitnami/orcapods/restart.sh]}</pre>"
end