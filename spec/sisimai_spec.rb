require 'spec_helper'

describe Sisimai do
  it 'has a version number' do
    expect(Sisimai::VERSION).not_to be nil
  end

  it 'does version() method' do
    expect(Sisimai.version()).to eq(Sisimai::VERSION)
  end

  it 'does sysname() method' do
    expect(Sisimai.sysname()).to eq('bouncehammer')
  end

  it 'does libname() method' do
    expect(Sisimai.libname()).to eq('Sisimai')
  end
end
