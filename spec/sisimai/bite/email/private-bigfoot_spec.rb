require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'Bigfoot'
isexpected = [
  { 'n' => '01001', 'r' => /spamdetected/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

