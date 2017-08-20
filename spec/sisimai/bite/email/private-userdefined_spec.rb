require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'UserDefined'
isexpected = []
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

