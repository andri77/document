require 'net/http'
require 'json'

class InvoiceApiClient
  attr_reader :base_url

  def initialize(base_url)
    @base_url = base_url
  end

  def health_check
    Net::HTTP.get_response(URI("#{@base_url}/api/invoices"))
  end

  def create(data)
    post('/api/invoices', data)
  end

  def get_xml(id)
    Net::HTTP.get_response(URI("#{@base_url}/api/invoices/#{id}/xml"))
  end

  def get_pdf(id)
    Net::HTTP.get_response(URI("#{@base_url}/api/invoices/#{id}/pdf"))
  end

  private

  def post(path, data)
    uri = URI("#{@base_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
    request.body = data.to_json
    http.request(request)
  end
end
