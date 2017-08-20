require 'spec_helper'
require './spec/sisimai/bite/json/code'
enginename = 'AmazonSES'
isexpected = []
Sisimai::Bite::JSON::Code.maketest(enginename, isexpected, true)

