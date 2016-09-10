source 'https://rubygems.org'

# Specify your gem's dependencies in sisimai.gemspec
platform :ruby do
  gemspec name: 'sisimai'
end

platform :jruby do
  gemspec name: 'sisimai-java'
end

# To execute `rake spec` on Travis-CI
#gem 'oj', '>= 2.14.4',       :platforms => :ruby
#gem 'jrjackson', '>= 0.3.8', :platforms => :jruby

group :development, :test do
  gem 'rake',  :require => false
  gem 'rspec', :require => false
  gem 'coveralls', :require => false
end

