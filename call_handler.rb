require 'sinatra'
require 'data_mapper'
require 'twilio-ruby'
require 'JSON/pure'
require './step'
require './metric'
require './content'

DataMapper.setup(:default, ENV['DATABASE_URL'] )

variants = ["A","B"]

# We can use this to setup the database, 
configure do
  #Finalize and store our models.
  DataMapper.finalize.auto_upgrade!

  #Create some steps...
  if Step.all.count == 0
    Step.create_tree
  end
end

# Render the default Step
post '/step' do
  variant = variants.sample
  step = Step.first(:root => true)
  Metric.create(cid: params[:CallSid], state: params[:CallStatus], step: step, variant: variant)
  step.to_twiml variant
end

#Get and render a step...
post '/step/:id/:variant' do
  step = Step.get(params[:id].to_i)  
  #If we are responding to a DTMF sequence, we can simply swap out the current step, and proceed as before.  
  if params[:Digits] != nil
    #We swap the step if the user has entered a keypress.
    step = step.children.find {|option| option[:gather] == params[:Digits] }.action
  end
  Metric.first(cid: params[:CallSid]).update(state: params[:CallStatus], step: step, variant: params[:variant])
  content_type 'text/xml'
  step.to_twiml params[:variant]
end

# Updates the metric by call SID after the call completes.
post '/fin' do
  Metric.first(cid: params[:CallSid]).update(state: params[:CallStatus])
end

# Builds up the tree...
get '/build' do
  Step.create_tree
  "DONE"
end

#Deletes everything to give a nice clean database...
get '/tank' do
  Content.all.each{|content| content.destroy}
  Step.all.each{|step| step.destroy}
  Metric.all.each{|metric| metric.destroy}
  "DONE"
end
