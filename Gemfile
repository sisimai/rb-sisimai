source 'https://rubygems.org'

# Specify your gem's dependencies in sisimai.gemspec
if RUBY_PLATFORM == 'java'
  gemspec :name => 'sisimai-java'
else
  gemspec :name => 'sisimai'
end

# To execute `rake spec` on Travis-CI
gem 'oj', '>= 2.14.4',       :platforms => :ruby
gem 'jrjackson', '>= 0.3.8', :platforms => :jruby

group :development, :test do
  gem 'rake',  :require => false
  gem 'rspec', :require => false
  gem 'coveralls', :require => false
end

