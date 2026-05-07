require 'json'
require 'nokogiri'
require_relative '../../app/models/invoice'
require_relative '../../pages/invoice_api_client'

VALID_INVOICE_DATA = {
  client_name: 'Acme Corp',
  currency: 'AUD',
  amount: 1500.0,
  item_count: 1,
  unit_price: 1500.0
}.freeze

def api
  @api ||= InvoiceApiClient.new(BASE_URL)
end

def reset_invoices
  Invoice.dataset.delete
  Invoice.db.run("DELETE FROM sqlite_sequence WHERE name='invoices'") rescue nil
end

Given('the invoice API is running') do
  api.health_check
rescue StandardError
  raise 'Sinatra app is not running. Start it with: bundle exec ruby app/app.rb'
end

Given('an invoice exists with ID {string}') do |_id|
  reset_invoices
  response = api.create(VALID_INVOICE_DATA)
  @invoice_id = JSON.parse(response.body)['id']
end

When('I POST to {string} with valid invoice data') do |_path|
  @last_response = api.create(VALID_INVOICE_DATA)
end

When('I GET {string}') do |path|
  actual_path = path.gsub('/1/', "/#{@invoice_id}/")
  case actual_path
  when %r{/api/invoices/(\d+)/xml$}
    @last_response = api.get_xml(Regexp.last_match(1).to_i)
  when %r{/api/invoices/(\d+)/pdf$}
    @last_response = api.get_pdf(Regexp.last_match(1).to_i)
  else
    @last_response = Net::HTTP.get_response(URI("#{BASE_URL}#{actual_path}"))
  end
end

Then('the response status should be {int}') do |expected_status|
  expect(@last_response.code.to_i).to eq(expected_status)
end

Then('the response body should contain a valid invoice ID') do
  body = JSON.parse(@last_response.body)
  expect(body['id']).to be_a(Integer)
  expect(body['id']).to be > 0
end

Then('the response content-type should be {string}') do |expected_ct|
  expect(@last_response['content-type']).to include(expected_ct)
end

Then('the XML should contain element {string}') do |xpath|
  doc = Nokogiri::XML(@last_response.body)
  parts = xpath.split('/')
  node = doc.root
  parts[1..].each do |part|
    node = node.at_xpath(part)
    raise "XML element '#{part}' not found in path '#{xpath}'" unless node
  end
end

Then('the XML element {string} should equal {string}') do |xpath, expected_value|
  doc = Nokogiri::XML(@last_response.body)
  parts = xpath.split('/')
  node = doc.root
  parts[1..].each { |part| node = node.at_xpath(part) }
  expect(node.text).to eq(expected_value)
end

Then('the PDF should not be empty') do
  expect(@last_response.body.length).to be > 100
  expect(@last_response.body[0..3]).to eq('%PDF')
end

When('I create an invoice with {string} line items at {string} each') do |items, price|
  @expected_items = items.to_i
  @expected_price = price.to_f
  data = {
    client_name: 'Test Client',
    currency: 'AUD',
    amount: (@expected_items * @expected_price).round(2),
    item_count: @expected_items,
    unit_price: @expected_price
  }
  response = api.create(data)
  @invoice_id = JSON.parse(response.body)['id']
  @last_response = api.get_xml(@invoice_id)
end

Then('the XML total should equal {string}') do |expected_total|
  doc = Nokogiri::XML(@last_response.body)
  total = doc.at_xpath('//Total').text
  expect(total).to eq(expected_total)
end

Then('the XML root element {string} should have attribute {string} equal to {string}') do |element, attr, value|
  doc = Nokogiri::XML(@last_response.body)
  expect(doc.root.name).to eq(element)
  expect(doc.root[attr]).to eq(value)
end

Then('the XML should have {string} line items') do |count|
  doc = Nokogiri::XML(@last_response.body)
  expect(doc.xpath('//LineItems/Item').count).to eq(count.to_i)
end

Then('the XML line items should each have unit price {string}') do |price|
  doc = Nokogiri::XML(@last_response.body)
  doc.xpath('//LineItems/Item/UnitPrice').each do |node|
    expect(node.text).to eq(price)
  end
end

Then('each XML line item should have a sequential {string} attribute') do |attr|
  doc = Nokogiri::XML(@last_response.body)
  doc.xpath('//LineItems/Item').each_with_index do |item, i|
    expect(item[attr]).to eq((i + 1).to_s)
  end
end

Then('the XML {string} element should not be empty') do |tag|
  doc = Nokogiri::XML(@last_response.body)
  node = doc.at_xpath("//#{tag}")
  expect(node).not_to be_nil, "Expected <#{tag}> element to exist in XML"
  expect(node.text.strip).not_to be_empty
end

Then('the PDF should match the visual baseline {string}') do |name|
  result = PdfComparison.compare(@last_response.body, name)
  expect(result[:diff_percent]).to be <= result[:threshold],
    "PDF diff #{result[:diff_percent].round(4)}% exceeds threshold #{result[:threshold]}%.\n" \
    "Actual: #{result[:actual_path]}\nDiff:   #{result[:diff_path]}"
end

Given('the {string} visual baseline is established') do |baseline_name|
  reset_invoices
  response = api.create(VALID_INVOICE_DATA)
  invoice_id = JSON.parse(response.body)['id']
  pdf_response = api.get_pdf(invoice_id)
  baseline_path = File.join(ENV.fetch('PDF_BASELINE_DIR', 'features/fixtures/baselines'), "#{baseline_name}.png")
  FileUtils.rm_f(baseline_path)
  PdfComparison.compare(pdf_response.body, baseline_name)
end

When('I create a different invoice and download its PDF') do
  reset_invoices
  different_data = { client_name: 'Acme Corp', currency: 'AUD', amount: 1550.0, item_count: 1, unit_price: 1550.0 }
  response = api.create(different_data)
  invoice_id = JSON.parse(response.body)['id']
  @last_response = api.get_pdf(invoice_id)
end

Then('the PDF should visually differ from baseline {string}') do |baseline_name|
  result = PdfComparison.compare(@last_response.body, baseline_name)
  expect(result[:diff_percent]).to be > 0,
    "Expected PDF to differ from '#{baseline_name}' baseline but diff was 0%.\n" \
    "Actual: #{result[:actual_path]}\nDiff:   #{result[:diff_path]}"
end
