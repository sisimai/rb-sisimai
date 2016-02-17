require 'rspec/core/rake_task'
require 'bundler/gem_helper'
if RUBY_PLATFORM =~ /java/
  filename = 'sisimai-java'
else
  filename = 'sisimai'
end
Bundler::GemHelper.install_tasks :name => filename
RSpec::Core::RakeTask.new(:spec)

task :default => :spec

