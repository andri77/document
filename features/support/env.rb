require 'cucumber'
require 'selenium-webdriver'
require 'rspec/expectations'
require 'net/http'
require 'json'
require 'nokogiri'

BASE_URL = ENV.fetch('BASE_URL', 'http://localhost:4567')

World(RSpec::Matchers)

def api
  @api ||= InvoiceApiClient.new(BASE_URL)
end

def xml_doc
  Nokogiri::XML(@last_response.body)
end

def json_body
  JSON.parse(@last_response.body)
end
