require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'RFC3464'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]1[.]1\z/,     'r' => /mailboxfull/, 'a' => /dovecot/, 'b' => /\A1\z/ },
  { 'n' => '02', 's' => /\A[45][.]0[.]\d+\z/,'r' => /(?:undefined|filtered|expired)/, 'a' => /RFC3464/, 'b' => /\d\z/ },
  { 'n' => '03', 's' => /\A[45][.]0[.]\d+\z/,'r' => /(?:undefined|expired)/, 'a' => /RFC3464/, 'b' => /\d\z/ },
  { 'n' => '04', 's' => /\A5[.]5[.]0\z/,     'r' => /mailererror/, 'a' => /RFC3464/, 'b' => /\A1\z/ },
  { 'n' => '05', 's' => /\A5[.]2[.]1\z/,     'r' => /filtered/,    'a' => /RFC3464/,    'b' => /\A1\z/ },
  { 'n' => '06', 's' => /\A5[.]5[.]0\z/,     'r' => /userunknown/, 'a' => /mail.local/, 'b' => /\A0\z/ },
  { 'n' => '07', 's' => /\A4[.]4[.]0\z/,     'r' => /expired/,     'a' => /RFC3464/, 'b' => /\A1\z/ },
  { 'n' => '08', 's' => /\A5[.]7[.]1\z/,     'r' => /spamdetected/,'a' => /RFC3464/, 'b' => /\A1\z/ },
  { 'n' => '09', 's' => /\A4[.]3[.]0\z/,     'r' => /mailboxfull/, 'a' => /RFC3464/, 'b' => /\A1\z/ },
  { 'n' => '22', 's' => /\A5[.]0[.]\d+\z/,   'r' => /hostunknown/, 'a' => /RFC3464/, 'b' => /\A0\z/ },
  { 'n' => '23', 's' => /\A5[.]0[.]\d+\z/,   'r' => /mailboxfull/, 'a' => /RFC3464/, 'b' => /\A1\z/ },
  { 'n' => '25', 's' => /\A5[.]0[.]\d+\z/,   'r' => /onhold/,      'a' => /RFC3464/, 'b' => /\d\z/ },
  { 'n' => '26', 's' => /\A5[.]1[.]1\z/,     'r' => /userunknown/, 'a' => /RFC3464/, 'b' => /\A0\z/ },
  { 'n' => '27', 's' => /\A4[.]4[.]6\z/,     'r' => /networkerror/,'a' => /RFC3464/, 'b' => /\A1\z/ },
  { 'n' => '28', 's' => /\A2[.]1[.]5\z/,     'r' => /delivered/,   'a' => /RFC3464/, 'b' => /\A-1\z/ },
  { 'n' => '29', 's' => /\A5[.]5[.]0\z/,     'r' => /syntaxerror/, 'a' => /RFC3464/, 'b' => /\A1\z/ },
  { 'n' => '33', 's' => /\A5[.]2[.]0\z/,     'r' => /spamdetected/,'a' => /RFC3464/, 'b' => /\A1\z/ },
  { 'n' => '34', 's' => /\A5[.]0[.]\d+\z/,   'r' => /networkerror/,'a' => /RFC3464/, 'b' => /\A1\z/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected)
