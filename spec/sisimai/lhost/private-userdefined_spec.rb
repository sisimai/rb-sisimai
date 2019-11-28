require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'UserDefined'
isexpected = []
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

