require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'MailRu'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]1[.]1\z/,  'r' => /userunknown/,'b' => /\A0\z/ },
  { 'n' => '02', 's' => /\A5[.]2[.]2\z/,  'r' => /mailboxfull/,'b' => /\A1\z/ },
  { 'n' => '03', 's' => /\A5[.][12][.][12]\z/, 'r' => /(?:userunknown|mailboxfull)/, 'b' => /\A[01]\z/ },
  { 'n' => '04', 's' => /\A5[.]1[.]1\z/,  'r' => /userunknown/,'b' => /\A0\z/ },
  { 'n' => '05', 's' => /\A5[.]0[.].+\z/, 'r' => /notaccept/,  'b' => /\A0\z/ },
  { 'n' => '06', 's' => /\A5[.]0[.].+\z/, 'r' => /hostunknown/,'b' => /\A0\z/ },
  { 'n' => '07', 's' => /\A5[.]0[.].+\z/, 'r' => /filtered/,   'b' => /\A1\z/ },
  { 'n' => '08', 's' => /\A5[.]0[.].+\z/, 'r' => /userunknown/,'b' => /\A0\z/ },
  { 'n' => '09', 's' => /\A5[.]1[.]8\z/,  'r' => /rejected/,   'b' => /\A1\z/ },
  { 'n' => '10', 's' => /\A5[.]0[.]\d+\z/,'r' => /expired/,    'b' => /\A1\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

