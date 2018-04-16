require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'MessageLabs'
isexpected = [
    { 'n' => '02', 's' => /\A5[.]0[.]0\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected)

