source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.0'

gem 'rails', '~> 7.1'
gem 'pg', '~> 1.1'
gem 'puma', '~> 6.0'
gem 'sprockets-rails'
gem 'importmap-rails'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'jbuilder'
gem 'redis', '~> 5.0'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
gem 'bootsnap', require: false

# Auth
gem 'devise'

# Authorization
gem 'pundit'

# Roles
gem 'rolify'

# File uploads
gem 'carrierwave', '~> 2.0'
gem 'fog-aws'
gem 'mini_magick'           # video thumbnail processing

# Payments
gem 'stripe'
gem 'pay', '~> 7.0'         # Stripe subscription wrapper

# Background jobs
gem 'sidekiq', '~> 7.0'
gem 'sidekiq-status'

# Pagination
gem 'kaminari'

# ENV management
gem 'dotenv-rails', groups: [:development, :test]

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'pry-rails'
  gem 'debug', platforms: %i[mri mingw x64_mingw]
end

group :development do
  gem 'web-console'
  gem 'bullet'              # N+1 query detection
  gem 'annotate'
end

group :test do
  gem 'shoulda-matchers'
  gem 'capybara'
  gem 'selenium-webdriver'
end
