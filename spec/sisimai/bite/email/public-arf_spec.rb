require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'ARF'
isexpected = [
  { 'n' => '01', 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => /\A-1\z/ },
  { 'n' => '02', 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => /\A-1\z/ },
  { 'n' => '03', 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => /\A-1\z/ },
  { 'n' => '04', 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => /\A-1\z/ },
  { 'n' => '05', 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => /\A-1\z/ },
  { 'n' => '06', 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => /\A-1\z/ },
  { 'n' => '07', 's' => /\A\z/, 'r' => /feedback/, 'f' => /auth-failure/, 'b' => /\A-1\z/ },
  { 'n' => '08', 's' => /\A\z/, 'r' => /feedback/, 'f' => /auth-failure/, 'b' => /\A-1\z/ },
  { 'n' => '09', 's' => /\A\z/, 'r' => /feedback/, 'f' => /auth-failure/, 'b' => /\A-1\z/ },
  { 'n' => '10', 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => /\A-1\z/ },
  { 'n' => '11', 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => /\A-1\z/ },
  { 'n' => '12', 's' => /\A\z/, 'r' => /feedback/, 'f' => /opt-out/, 'b' => /\A-1\z/ },
  { 'n' => '13', 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/,   'b' => /\A-1\z/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected)

