require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'Yandex'
isexpected = [
  { 'n' => '01001', 'r' => /userunknown/ },
  { 'n' => '01002', 'r' => /(?:userunknown|mailboxfull)/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

