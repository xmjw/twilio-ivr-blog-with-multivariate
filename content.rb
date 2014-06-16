#Just in case we reuse this elsewhere.
require 'data_mapper'
require './step'

#A model to hold the call tree.
class Content
  include DataMapper::Resource
  
  property :id, Serial
  property :say, String
  property :voice, String
  property :language, String
  property :variant, String
  property :default, Boolean
  
  belongs_to :step
  
  def to_twiml parent
    #This particular variant can render out the TwiML.
    parent.Say say, :language => language, :voice => voice
  end
end
