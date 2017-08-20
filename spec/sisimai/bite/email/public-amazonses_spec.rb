require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'AmazonSES'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]7[.]1\z/, 'r' => /securityerror/, 'b' => /\A1\z/ },
  { 'n' => '02', 's' => /\A5[.]3[.]0\z/, 'r' => /filtered/,      'b' => /\A1\z/ },
  { 'n' => '03', 's' => /\A5[.]2[.]2\z/, 'r' => /mailboxfull/,   'b' => /\A1\z/ },
  { 'n' => '04', 's' => /\A5[.]4[.]7\z/, 'r' => /expired/,       'b' => /\A1\z/ },
  { 'n' => '05', 's' => /\A5[.]1[.]1\z/, 'r' => /userunknown/,   'b' => /\A0\z/ },
  { 'n' => '06', 's' => /\A5[.]1[.]1\z/, 'r' => /userunknown/,   'b' => /\A0\z/ },
  { 'n' => '07', 's' => /\A5[.]7[.]6\z/, 'r' => /securityerror/, 'b' => /\A1\z/ },
  { 'n' => '08', 's' => /\A5[.]7[.]9\z/, 'r' => /securityerror/, 'b' => /\A1\z/ },
  { 'n' => '09', 's' => /\A5[.]1[.]1\z/, 'r' => /userunknown/,   'b' => /\A0\z/ },
  { 'n' => '10', 's' => /\A5[.]1[.]1\z/, 'r' => /userunknown/,   'b' => /\A0\z/ },
  { 'n' => '11', 's' => /\A\z/,          'r' => /feedback/,      'b' => /\A-1\z/},
  { 'n' => '12', 's' => /\A2[.]6[.]0\z/, 'r' => /delivered/,     'b' => /\A-1\z/},
  { 'n' => '13', 's' => /\A2[.]6[.]0\z/, 'r' => /delivered/,     'b' => /\A-1\z/},
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected)

