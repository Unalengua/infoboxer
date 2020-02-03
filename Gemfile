source 'https://rubygems.org'

gemspec

# gem 'mediawiktory', github: 'molybdenum-99/mediawiktory', branch: 'develop'

group :docs do
  gem 'dokaz', git: 'https://github.com/zverok/dokaz.git'
  gem 'yard', '~> 0.9'
  gem 'redcarpet'
  #gem 'inch'
end

group :development do
  gem 'rake'
  gem 'ruby-prof' unless RUBY_PLATFORM.include?('java')
  gem 'rubygems-tasks'
  gem 'byebug' unless RUBY_PLATFORM.include?('java')
  gem 'rubocop', '~> 0.52.1'
  gem 'rubocop-rspec', '~> 1.20'
end

group :test do
  gem 'rspec', '~> 3'
  gem 'rspec-its', '~> 1'
  gem 'vcr'
  gem 'webmock'
  gem 'timecop'
  gem 'saharspec', '= 0.0.4'
  gem 'coveralls', require: false
  gem 'yard-junk', '~> 0.0.7'
end
