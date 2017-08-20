require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'RFC3834'
isexpected = [
  { 'n' => '01002', 'r' => /vacation/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

