#Just in case we reuse this elsewhere.
require 'data_mapper'
require 'twilio-ruby'
require './metric'
require './content'

#A model to hold the call tree.
class Step
  include DataMapper::Resource
  property :id, Serial
  property :sequence, Integer
  property :gather, String
  property :root, Boolean, :default => false
  property :goal, Boolean, :default => false

  belongs_to :parent, :model => Step, :required => false
  has n, :children, :model => Step, :child_key => [ :parent_id ]
  belongs_to :action, :model => Step, :required => false
  has n, :content
  
  def self.create_tree
    # Create the first varaint of steps...
    top_step = Step.create(sequence: 0, gather: nil, root: true)
    owl_count = Step.create(sequence: 0, gather: nil, goal: true)
    operator = Step.create(sequence: 0, gather: nil)    
    option_one = Step.create(parent: top_step, sequence: 0, gather: "1", action: owl_count)
    option_two = Step.create(parent: top_step, sequence: 1, gather: "2", action: operator)

    # now we create the content blobs to attach to each step.
    Content.create(step: top_step, say: "Thank you for calling Twil'lio Owl Sanctuary.", voice: "alice", language: "en-gb", variant: "A", default: true)
    Content.create(step: owl_count, say: "Thank you. We have 3 Owls. Three.", voice: "alice", language: "en-gb", variant: "A", default: true)
    Content.create(step: operator, say: "This is a demo, we don't really have an operator.", voice: "alice", language: "en-gb", variant: "A", default: true)
    Content.create(step: option_one, say: "To hear how many Owls we have, press 1.", voice: "alice", language: "en-gb", variant: "A", default: true)
    Content.create(step: option_two, say: "To speak to an operator, press 2.", voice: "alice", language: "en-gb", variant: "A", default: true)
    
    # Now we can easily add a variant to any of these individually:
    
    # For example, this one uses the scientific order name for an Owl, and less formal language.
    variant = Content.create(step: option_one, say: "You need to hear how many strigiformes we have, 1.", voice: "alice", language: "en-gb", variant: "B", default: false)
    
    # Add the variant to the step:
  end
  
  def get_content variant
    c = content.first(:variant => variant)
    # in case there is no specific content for this variant, get the default one.
    c = content.first(:default => true) if !c
    c
  end
  
  def to_twiml variant
    #If an error occurs here, the exception will cause Twilio to read out the 'An Application Error has Occured' message.
    twiml = Twilio::TwiML::Response.new do |r|

      # Use the new content object to render the twiml...
      get_content(variant).to_twiml r

      if children.count > 0
        # Include tha variant in the callback URL, so we don't need to worry about extra reads and write to the DB.
        r.Gather action: "/step/#{id}/#{variant}", numDigits: 1 do |gather|
           children.each do |option|
             # Again, use the content object...
             option.get_content(variant).to_twiml(gather)
           end
        end
      else
        r.Say "Goodbye.", voice: 'alice', language: 'en-gb'
        r.Hanup
      end
    end
    twiml.text
  end
end
