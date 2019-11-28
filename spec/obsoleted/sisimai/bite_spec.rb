require 'spec_helper'
require 'sisimai/bite'

describe Sisimai::Bite do
  describe '.DELIVERYSTATUS' do
    it('returns Hash') { expect(Sisimai::Bite.DELIVERYSTATUS).to be_a Hash }
  end
  describe '.smtpagent' do
    it('returns String') { expect(Sisimai::Bite.smtpagent).to be_a Object::String }
  end
  describe '.description' do
    it('returns String') { expect(Sisimai::Bite.description).to be_a Object::String }
  end
end

