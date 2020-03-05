require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'GoogleGroups'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]0[.]\d+\z/, 'r' => /rejected/,   'b' => /\A1\z/ },
  { 'n' => '02', 's' => /\A5[.]0[.]\d+\z/, 'r' => /rejected/,   'b' => /\A1\z/ },
  { 'n' => '03', 's' => /\A5[.]0[.]\d+\z/, 'r' => /rejected/,   'b' => /\A1\z/ },
  { 'n' => '04', 's' => /\A5[.]0[.]\d+\z/, 'r' => /rejected/,   'b' => /\A1\z/ },
  { 'n' => '05', 's' => /\A5[.]0[.]\d+\z/, 'r' => /rejected/,   'b' => /\A1\z/ },
  { 'n' => '06', 's' => /\A5[.]0[.]\d+\z/, 'r' => /rejected/,   'b' => /\A1\z/ },
  { 'n' => '07', 's' => /\A5[.]0[.]\d+\z/, 'r' => /rejected/,   'b' => /\A1\z/ },
  { 'n' => '08', 's' => /\A5[.]0[.]\d+\z/, 'r' => /rejected/,   'b' => /\A1\z/ },
  { 'n' => '09', 's' => /\A5[.]0[.]\d+\z/, 'r' => /rejected/,   'b' => /\A1\z/ },
  { 'n' => '10', 's' => /\A5[.]0[.]\d+\z/, 'r' => /rejected/,   'b' => /\A1\z/ },
  { 'n' => '11', 's' => /\A5[.]0[.]\d+\z/, 'r' => /rejected/,   'b' => /\A1\z/ },
  { 'n' => '12', 's' => /\A5[.]0[.]\d+\z/, 'r' => /rejected/,   'b' => /\A1\z/ },
  { 'n' => '13', 's' => /\A5[.]0[.]\d+\z/, 'r' => /rejected/,   'b' => /\A1\z/ },
  { 'n' => '14', 's' => /\A5[.]0[.]\d+\z/, 'r' => /rejected/,   'b' => /\A1\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

