require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'V5sendmail'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]0[.]\d+\z/, 'r' => /expired/,     'b' => /\A1\z/ },
  { 'n' => '02', 's' => /\A5[.]0[.]\d+\z/, 'r' => /hostunknown/, 'b' => /\A0\z/ },
  { 'n' => '03', 's' => /\A5[.]0[.]\d+\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '04', 's' => /\A5[.]0[.]\d+\z/, 'r' => /hostunknown/, 'b' => /\A0\z/ },
  { 'n' => '05', 's' => /\A5[.]0[.]\d+\z/, 'r' => /(?:hostunknown|blocked|userunknown)/, 'b' => /\d\z/ },
  { 'n' => '06', 's' => /\A5[.]0[.]\d+\z/, 'r' => /norelaying/,  'b' => /\A1\z/ },
  { 'n' => '07', 's' => /\A5[.]0[.]\d+\z/, 'r' => /(?:hostunknown|blocked|userunknown)/, 'b' => /\d\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

