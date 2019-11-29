require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'RFC3464'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]1[.]1\z/,     'r' => /mailboxfull/, 'a' => /dovecot/, 'b' => /\A1\z/ },
  { 'n' => '03', 's' => /\A5[.]0[.]0\z/,     'r' => /policyviolation/,'a' => /RFC3464/, 'b' => /\A1\z/ },
  { 'n' => '04', 's' => /\A5[.]5[.]0\z/,     'r' => /mailererror/, 'a' => /RFC3464/, 'b' => /\A1\z/ },
  { 'n' => '05', 's' => /\A5[.]2[.]1\z/,     'r' => /filtered/,    'a' => /RFC3464/,    'b' => /\A1\z/ },
  { 'n' => '06', 's' => /\A5[.]5[.]0\z/,     'r' => /userunknown/, 'a' => /mail.local/, 'b' => /\A0\z/ },
  { 'n' => '07', 's' => /\A4[.]4[.]0\z/,     'r' => /expired/,     'a' => /RFC3464/, 'b' => /\A1\z/ },
  { 'n' => '08', 's' => /\A5[.]7[.]1\z/,     'r' => /spamdetected/,'a' => /RFC3464/, 'b' => /\A1\z/ },
  { 'n' => '09', 's' => /\A[45][.]\d[.]\d+\z/,'r' => /(?:mailboxfull|undefined)/,'a' => /RFC3464/, 'b' => /\A1\z/ },
  { 'n' => '10', 's' => /\A5[.]1[.]6\z/,     'r' => /hasmoved/,    'a' => /RFC3464/, 'b' => /\A0\z/ },
  { 'n' => '26', 's' => /\A5[.]1[.]1\z/,     'r' => /userunknown/, 'a' => /RFC3464/, 'b' => /\A0\z/ },
  { 'n' => '28', 's' => /\A2[.]1[.]5\z/,     'r' => /delivered/,   'a' => /RFC3464/, 'b' => /\A-1\z/ },
  { 'n' => '29', 's' => /\A5[.]5[.]0\z/,     'r' => /syntaxerror/, 'a' => /RFC3464/, 'b' => /\A1\z/ },
  { 'n' => '34', 's' => /\A5[.]0[.]\d+\z/,   'r' => /networkerror/,'a' => /RFC3464/, 'b' => /\A1\z/ },
  { 'n' => '35', 's' => /\A[45][.]0[.]0\z/,  'r' => /(?:filtered|expired|rejected)/, 'a' => /RFC3464/, 'b' => /\A1\z/ },
  { 'n' => '36', 's' => /\A4[.]0[.]0\z/,     'r' => /expired/,     'a' => /RFC3464/, 'b' => /\A1\z/ },
  { 'n' => '37', 's' => /\A5[.]0[.]\d+\z/,   'r' => /hostunknown/, 'a' => /RFC3464/, 'b' => /\A0\z/ },
  { 'n' => '38', 's' => /\A5[.]0[.]\d+\z/,   'r' => /mailboxfull/, 'a' => /RFC3464/, 'b' => /\A1\z/ },
  { 'n' => '39', 's' => /\A5[.]0[.]\d+\z/,   'r' => /onhold/,      'a' => /RFC3464/, 'b' => /\A1\z/ },
  { 'n' => '40', 's' => /\A4[.]4[.]6\z/,     'r' => /networkerror/,'a' => /RFC3464/, 'b' => /\A1\z/ },
  { 'n' => '41', 's' => /\A\z/,              'r' => /vacation/,    'a' => /RFC3464/, 'b' => /\A-1\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)
