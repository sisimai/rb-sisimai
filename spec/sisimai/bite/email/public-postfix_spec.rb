require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'Postfix'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]1[.]1\z/,   'r' => /mailererror/,   'b' => /\A1\z/ },
  { 'n' => '02', 's' => /\A5[.][12][.]1\z/,'r' => /(?:filtered|userunknown)/, 'b' => /\d\z/ },
  { 'n' => '03', 's' => /\A5[.]0[.]0\z/,   'r' => /filtered/,      'b' => /\A1\z/ },
  { 'n' => '04', 's' => /\A5[.]1[.]1\z/,   'r' => /userunknown/,   'b' => /\A0\z/ },
  { 'n' => '05', 's' => /\A4[.]1[.]1\z/,   'r' => /userunknown/,   'b' => /\A0\z/ },
  { 'n' => '06', 's' => /\A5[.]4[.]4\z/,   'r' => /hostunknown/,   'b' => /\A0\z/ },
  { 'n' => '07', 's' => /\A5[.]0[.]\d+\z/, 'r' => /filtered/,      'b' => /\A1\z/ },
  { 'n' => '08', 's' => /\A4[.]4[.]1\z/,   'r' => /expired/,       'b' => /\A1\z/ },
  { 'n' => '09', 's' => /\A4[.]3[.]2\z/,   'r' => /toomanyconn/,   'b' => /\A1\z/ },
  { 'n' => '10', 's' => /\A5[.]1[.]8\z/,   'r' => /rejected/,      'b' => /\A1\z/ },
  { 'n' => '11', 's' => /\A5[.]1[.]8\z/,   'r' => /rejected/,      'b' => /\A1\z/ },
  { 'n' => '12', 's' => /\A5[.]1[.]1\z/,   'r' => /userunknown/,   'b' => /\A0\z/ },
  { 'n' => '13', 's' => /\A5[.]2[.][12]\z/,'r' => /(?:userunknown|mailboxfull)/, 'b' => /\d\z/ },
  { 'n' => '14', 's' => /\A5[.]1[.]1\z/,   'r' => /userunknown/,   'b' => /\A0\z/ },
  { 'n' => '15', 's' => /\A4[.]4[.]1\z/,   'r' => /expired/,       'b' => /\A1\z/ },
  { 'n' => '16', 's' => /\A5[.]1[.]6\z/,   'r' => /hasmoved/,      'b' => /\A0\z/ },
  { 'n' => '17', 's' => /\A5[.]4[.]4\z/,   'r' => /networkerror/,  'b' => /\A1\z/ },
  { 'n' => '21', 's' => /\A5[.]0[.]\d+\z/, 'r' => /networkerror/,  'b' => /\A1\z/ },
  { 'n' => '28', 's' => /\A5[.]7[.]1\z/,   'r' => /policyviolation/, 'b' => /\A1\z/ },
  { 'n' => '29', 's' => /\A5[.]7[.]1\z/,   'r' => /policyviolation/, 'b' => /\A1\z/ },
  { 'n' => '30', 's' => /\A5[.]4[.]1\z/,   'r' => /userunknown/,   'b' => /\A0\z/ },
  { 'n' => '31', 's' => /\A5[.]1[.]1\z/,   'r' => /userunknown/,   'b' => /\A0\z/ },
  { 'n' => '32', 's' => /\A5[.]1[.]1\z/,   'r' => /userunknown/,   'b' => /\A0\z/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected)

