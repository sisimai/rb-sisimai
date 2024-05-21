require 'simplecov'
require 'simplecov-cobertura'

SimpleCov.start { add_filter ['test/public/', 'test/private/'] }
SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

LhostEngine = './test/public/lhost-engine-test.rb'
RhostEngine = './test/public/rhost-engine-test.rb'
load LhostEngine
load RhostEngine

Dir.glob('./test/public/*.rb').each do |e|
  next if e == LhostEngine
  next if e == RhostEngine
  require e
end

