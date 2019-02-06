require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'ARF'
isexpected = [
  { 'n' => '01', 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => /\A-1\z/ },
  { 'n' => '02', 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => /\A-1\z/ },
  { 'n' => '11', 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => /\A-1\z/ },
  { 'n' => '12', 's' => /\A\z/, 'r' => /feedback/, 'f' => /opt-out/, 'b' => /\A-1\z/ },
  { 'n' => '14', 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/,   'b' => /\A-1\z/ },
  { 'n' => '15', 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => /\A-1\z/ },
  { 'n' => '16', 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => /\A-1\z/ },
  { 'n' => '17', 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => /\A-1\z/ },
  { 'n' => '18', 's' => /\A\z/, 'r' => /feedback/, 'f' => /auth-failure/, 'b' => /\A-1\z/ },
  { 'n' => '19', 's' => /\A\z/, 'r' => /feedback/, 'f' => /auth-failure/, 'b' => /\A-1\z/ },
  { 'n' => '20', 's' => /\A\z/, 'r' => /feedback/, 'f' => /auth-failure/, 'b' => /\A-1\z/ },
  { 'n' => '21', 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => /\A-1\z/ },
  { 'n' => '22', 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => /\A-1\z/ },
  { 'n' => '23', 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => /\A-1\z/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected)

