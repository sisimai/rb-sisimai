require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'Google'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]1[.]1\z/,   'r' => /userunknown/,   'b' => /\A0\z/ },
  { 'n' => '03', 's' => /\A5[.]7[.]0\z/,   'r' => /filtered/,      'b' => /\A1\z/ },
  { 'n' => '04', 's' => /\A5[.]7[.]1\z/,   'r' => /blocked/,       'b' => /\A1\z/ },
  { 'n' => '05', 's' => /\A5[.]7[.]1\z/,   'r' => /securityerror/, 'b' => /\A1\z/ },
  { 'n' => '06', 's' => /\A4[.]2[.]2\z/,   'r' => /mailboxfull/,   'b' => /\A1\z/ },
  { 'n' => '07', 's' => /\A5[.]0[.]\d+\z/, 'r' => /systemerror/,   'b' => /\A1\z/ },
  { 'n' => '08', 's' => /\A5[.]0[.]\d+\z/, 'r' => /expired/,       'b' => /\A1\z/ },
  { 'n' => '09', 's' => /\A4[.]0[.]\d+\z/, 'r' => /expired/,       'b' => /\A1\z/ },
  { 'n' => '10', 's' => /\A5[.]0[.]\d+\z/, 'r' => /expired/,       'b' => /\A1\z/ },
  { 'n' => '11', 's' => /\A5[.]0[.]\d+\z/, 'r' => /expired/,       'b' => /\A1\z/ },
  { 'n' => '15', 's' => /\A5[.]0[.]\d+\z/, 'r' => /expired/,       'b' => /\A1\z/ },
  { 'n' => '16', 's' => /\A5[.]2[.]2\z/,   'r' => /mailboxfull/,   'b' => /\A1\z/ },
  { 'n' => '17', 's' => /\A4[.]0[.]\d+\z/, 'r' => /expired/,       'b' => /\A1\z/ },
  { 'n' => '18', 's' => /\A5[.]1[.]1\z/,   'r' => /userunknown/,   'b' => /\A0\z/ },
  { 'n' => '19', 's' => /\A5[.]0[.]\d+\z/, 'r' => /mailboxfull/,   'b' => /\A1\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

