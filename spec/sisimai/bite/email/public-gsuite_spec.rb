require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'GSuite'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]1[.]0\z/,   'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '02', 's' => /\A5[.]0[.]0\z/,   'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '03', 's' => /\A4[.]0[.]0\z/,   'r' => /notaccept/,   'b' => /\A1\z/ },
  { 'n' => '04', 's' => /\A4[.]0[.]0\z/,   'r' => /networkerror/,'b' => /\A1\z/ },
  { 'n' => '05', 's' => /\A4[.]0[.]0\z/,   'r' => /networkerror/,'b' => /\A1\z/ },
  { 'n' => '06', 's' => /\A4[.]4[.]1\z/,   'r' => /expired/,     'b' => /\A1\z/ },
  { 'n' => '07', 's' => /\A4[.]4[.]1\z/,   'r' => /expired/,     'b' => /\A1\z/ },
  { 'n' => '08', 's' => /\A5[.]0[.]0\z/,   'r' => /filtered/,    'b' => /\A1\z/ },
  { 'n' => '09', 's' => /\A5[.]0[.]0\z/,   'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '10', 's' => /\A4[.]0[.]0\z/,   'r' => /notaccept/,   'b' => /\A1\z/ },
  { 'n' => '11', 's' => /\A5[.]1[.]8\z/,   'r' => /rejected/,    'b' => /\A1\z/ },
  { 'n' => '12', 's' => /\A5[.]0[.]0\z/,   'r' => /spamdetected/,'b' => /\A1\z/ },
  { 'n' => '13', 's' => /\A4[.]0[.]0\z/,   'r' => /networkerror/,'b' => /\A1\z/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected)

