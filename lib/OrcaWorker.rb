require 'resque'

ActiveRecord::Base.class_eval do
  # @queue = :orcaworker
  
  # delayed_job style async helpers
  # https://github.com/defunkt/resque/blob/master/examples/async_helper.rb
  
  # Pod.async(:create_message,id,arg1,arg2) will result in
  # Pod.find(id).create_message(arg1,arg) on the worker box
  # note - args must be json serializable
  
  # User.async(:create,nil,{:name=>'gene'})
  
  # User.async(:update_attribute,3,'name','gene')
  
  def self.perform(method, *args)
    self.send(method, *args)
  end
  
  def self.async(method, *args)
    Resque.enqueue(self, method, *args)
  end
end
