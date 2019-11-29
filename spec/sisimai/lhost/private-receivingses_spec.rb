require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'ReceivingSES'
isexpected = []
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

