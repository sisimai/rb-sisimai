require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'MailMarshalSMTP'
isexpected = [
  { 'n' => '01001', 'r' => /filtered/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

