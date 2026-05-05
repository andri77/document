require 'cucumber'
require 'selenium-webdriver'
require 'rspec/expectations'
require 'net/http'
require 'json'
require 'nokogiri'

BASE_URL = ENV.fetch('BASE_URL', 'http://localhost:4567')
ENV['PDF_DIFF_THRESHOLD'] ||= '0.1'

World(RSpec::Matchers)
