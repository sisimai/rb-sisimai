require 'spec_helper'
require './spec/obsoleted/sisimai/bite/json/code'
enginename = 'AmazonSES'
isexpected = []
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

