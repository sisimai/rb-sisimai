require 'spec_helper'
require './spec/sisimai/bite/json/code'
enginename = 'SendGrid'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]0[.]\d+\z/, 'r' => /filtered/,    'b' => /\A1\z/ },
  { 'n' => '02', 's' => /\A5[.].[.]\d+\z/, 'r' => /(?:mailboxfull|filtered)/, 'b' => /\A1\z/ },
  { 'n' => '03', 's' => /\A5[.]1[.]1\z/,   'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '04', 's' => /\A5[.]0[.]\d+\z/, 'r' => /filtered/,    'b' => /\A1\z/ },
  { 'n' => '05', 's' => /\A5[.]0[.]\d+\z/, 'r' => /filtered/,    'b' => /\A1\z/ },
  { 'n' => '06', 's' => /\A5[.]1[.]1\z/,   'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '07', 's' => /\A5[.]2[.]1\z/,   'r' => /filtered/,    'b' => /\A1\z/ },
  { 'n' => '08', 's' => /\A5[.]1[.]1\z/,   'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '09', 's' => /\A5[.]1[.]1\z/,   'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '10', 's' => /\A5[.]1[.]1\z/,   'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '11', 's' => /\A5[.]0[.]\d+\z/, 'r' => /hostunknown/, 'b' => /\A0\z/ },
  { 'n' => '12', 's' => /\A5[.]2[.]2\z/,   'r' => /mailboxfull/, 'b' => /\A1\z/ },
  { 'n' => '13', 's' => /\A2[.]0[.]0\z/,   'r' => /delivered/,   'b' => /\A-1\z/},
  { 'n' => '14', 's' => /\A5[.]7[.]13\z/,  'r' => /suspend/,     'b' => /\A1\z/ },
]
Sisimai::Bite::JSON::Code.maketest(enginename, isexpected)

