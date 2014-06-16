require 'sinatra'
require 'data_mapper'
require 'twilio-ruby'
require './step'
require './metric'

DataMapper.setup(:default, ENV['DATABASE_URL'])

# We can use this to setup the database, 
configure do
  #Finalize and store our models.
  DataMapper.finalize.auto_upgrade!

  #Create some steps...
  if Step.all.count == 0
    Step.create_tree
  end
end
 
#Simple Page to show all the steps.
get '/' do
  @steps = Step.all
  erb :index, :layout => :main_layout
end

get '/metric' do
  @metrics = Metric.all
  #erb :metric, :layout => :main_layout
end

post '/step' do 
  step = Step.first(:root => true)
  Metric.create(cid: params[:CallSid], state: params[:CallStatus], step: step)
  step.to_twiml
end

#Get and render a step...
post '/step/:id' do
  step = Step.get(params[:id])  
  #If we are responding to a DTMF sequence, we can simply swap out the current step, and proceed as before.  
  if params[:Digits] != nil
    #We swap the step if the user has entered a keypress.
    step = step.children.find {|option| option[:gather] == params[:Digits] }.action
  end

  Metric.create(cid: params[:CallSid], state: params[:CallStatus], step: step)
  content_type 'text/xml'
  step.to_twiml
end

post '/fin' do
  Metric.create(cid: params[:CallSid], state: params[:CallStatus])
end

get '/build' do
  Step.create_tree
  "DONE"
end

#Deletes everything to give a nice clean database...
get '/tank' do
  Step.all.each{|step| step.destroy}
  Metric.all.each{|metric| metric.destroy}
  "DONE"
end

