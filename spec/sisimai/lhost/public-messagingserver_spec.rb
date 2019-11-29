require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'MessagingServer'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]1[.]1\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '02', 's' => /\A5[.]2[.]0\z/, 'r' => /mailboxfull/, 'b' => /\A1\z/ },
  { 'n' => '03', 's' => /\A5[.]7[.]1\z/, 'r' => /filtered/,    'b' => /\A1\z/ },
  { 'n' => '04', 's' => /\A5[.]2[.]2\z/, 'r' => /mailboxfull/, 'b' => /\A1\z/ },
  { 'n' => '05', 's' => /\A5[.]4[.]4\z/, 'r' => /hostunknown/, 'b' => /\A0\z/ },
  { 'n' => '06', 's' => /\A5[.]2[.]1\z/, 'r' => /filtered/,    'b' => /\A1\z/ },
  { 'n' => '07', 's' => /\A4[.]4[.]7\z/, 'r' => /expired/,     'b' => /\A1\z/ },
  { 'n' => '08', 's' => /\A5[.]0[.]0\z/, 'r' => /filtered/,    'b' => /\A1\z/ },
  { 'n' => '09', 's' => /\A5[.]0[.]0\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '10', 's' => /\A5[.]0[.]\d+\z/, 'r' => /notaccept/, 'b' => /\A0\z/ },
  { 'n' => '11', 's' => /\A5[.]1[.]8\z/, 'r' => /rejected/,    'b' => /\A1\z/ },
  { 'n' => '12', 's' => /\A4[.]2[.]2\z/, 'r' => /mailboxfull/, 'b' => /\A1\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

