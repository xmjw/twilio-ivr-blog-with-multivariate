#Just in case we reuse this elsewhere.
require 'data_mapper'
require 'twilio-ruby'
require './metric'

#A model to hold the call tree.
class Step
  include DataMapper::Resource
  property :id, Serial
  property :say, String
  property :sequence, Integer
  property :gather, String
  property :root, Boolean, :default => false
  property :goal, Boolean, :default => true
 
  belongs_to :parent, :model => Step, :required => false
  has n, :children, :model => Step, :child_key => [ :parent_id ]
  belongs_to :action, :model => Step, :required => false
  
  def self.create_tree
    # Create the first varaint of steps...
    topStep = Step.create(say: "Thank you for calling Twil'lio Owl Sanctuary.", sequence: 0, gather: nil, root: true)
    owl_count = Step.create(say: "Thank you. We have 3 Owls. Three.", sequence: 0, gather: nil, goal: true)
    operator = Step.create(say: "This is a demo, we don't really have an operator.",  sequence: 0, gather: nil, goal: true)    
    Step.create(say: "To hear how many Owls we have, press 1.", parent: topStep, sequence: 0, gather: "1", action: owl_count)
    Step.create(say: "To speak to an operator, press 2.", parent: topStep, sequence: 1, gather: "2", action: operator,)

  end
  
  def to_twiml
    #If an error occurs here, the exception will cause Twilio to read out the 'An Application Error has Occured' message.
    twiml = Twilio::TwiML::Response.new do |r|

      r.Say say, :language => "en-gb", :voice => "alice"

      if children.count > 0
        r.Gather action: "/step/#{id}" do |gather|
           children.each do |options|
             gather.Say options.say, :language => "en-gb", :voice => "alice"
           end
        end
      else
        r.Say "Goodbye.", :language => "en-gb", :voice => "alice"
        r.Hangup
      end
    end
    twiml.text
  end
  
  
end