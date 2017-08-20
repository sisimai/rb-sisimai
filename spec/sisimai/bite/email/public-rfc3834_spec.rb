require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'RFC3834'
isexpected = [
  { 'n' => '01', 's' => /\A\z/, 'r' => /vacation/, 'b' => /\A-1\z/ },
  { 'n' => '02', 's' => /\A\z/, 'r' => /vacation/, 'b' => /\A-1\z/ },
  { 'n' => '03', 's' => /\A\z/, 'r' => /vacation/, 'b' => /\A-1\z/ },
  { 'n' => '04', 's' => /\A\z/, 'r' => /vacation/, 'b' => /\A-1\z/ },
  { 'n' => '05', 's' => /\A\z/, 'r' => /vacation/, 'b' => /\A-1\z/ },
  { 'n' => '06', 's' => /\A\z/, 'r' => /vacation/, 'b' => /\A-1\z/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected)

