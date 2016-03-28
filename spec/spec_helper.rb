$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'easy_css_regressions'

require 'rack'
require 'capybara'
require 'capybara/rspec'
require 'capybara/poltergeist'
require 'launchy'

Capybara.javascript_driver = :poltergeist
Capybara.default_driver = :poltergeist
Capybara.app = Rack::Directory.new('spec/public')

RSpec.configure do |config|
  
  config.include EasyCssRegressions, type: :feature
  

  config.order = "random"
end