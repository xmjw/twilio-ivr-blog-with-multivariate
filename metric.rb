#Just in case we reuse this elsewhere.
require 'data_mapper'
require './step'

#A model to hold the call tree.
class Metric
  include DataMapper::Resource
  property :id, Serial
  property :cid, String
  property :state, String
  belongs_to :step, :required => false
end