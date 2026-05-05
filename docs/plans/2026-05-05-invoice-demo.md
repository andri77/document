# Invoice Demo App Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Ruby/Sinatra invoice app with a full Cucumber BDD test suite covering UI (Selenium) and API (XML/PDF) testing for an EY interview demo.

**Architecture:** Sinatra serves a dashboard UI and JSON/XML/PDF API endpoints. Sequel+SQLite stores invoices. Nokogiri generates XML, Prawn generates PDFs. Cucumber drives Selenium for UI and Net::HTTP for API tests.

**Tech Stack:** Ruby 3.2, Sinatra, Sequel, SQLite3, Nokogiri, Prawn, Cucumber, Selenium-WebDriver, ChromeDriver, GitHub Actions

---

### Task 1: Project Bootstrap — Gemfile and Git

**Files:**
- Create: `Gemfile`
- Create: `.gitignore`
- Create: `README.md`

**Step 1: Create Gemfile**

```ruby
# Gemfile
source 'https://rubygems.org'

ruby '3.2.0'

# App
gem 'sinatra', '~> 3.2'
gem 'sinatra-contrib', '~> 3.2'
gem 'sequel', '~> 5.78'
gem 'sqlite3', '~> 1.7'
gem 'nokogiri', '~> 1.16'
gem 'prawn', '~> 2.5'
gem 'puma', '~> 6.4'
gem 'json', '~> 2.7'

# Test
group :test do
  gem 'cucumber', '~> 9.2'
  gem 'selenium-webdriver', '~> 4.20'
  gem 'webdrivers', '~> 5.3'
  gem 'rspec-expectations', '~> 3.13'
  gem 'rack-test', '~> 2.1'
end
```

**Step 2: Create .gitignore**

```
*.sqlite3
reports/
.bundle/
vendor/
*.gem
.DS_Store
```

**Step 3: Install gems**

Run: `bundle install`
Expected: All gems installed, `Gemfile.lock` created

**Step 4: Create minimal README.md**

```markdown
# Invoice Demo App

A Ruby/Sinatra invoice system with Cucumber BDD tests (UI + API).

## Run the app
```bash
bundle exec ruby app/app.rb
```

## Run tests
```bash
bundle exec cucumber
```

## Run tests with HTML report
```bash
bundle exec cucumber --format html --out reports/cucumber_report.html --format pretty
```
```

**Step 5: Initial commit**

```bash
git add Gemfile Gemfile.lock .gitignore README.md
git commit -m "chore: bootstrap project with Gemfile and README"
```

---

### Task 2: Database Model

**Files:**
- Create: `app/models/invoice.rb`
- Create: `db/migrations/001_create_invoices.rb`

**Step 1: Create migration file**

```ruby
# db/migrations/001_create_invoices.rb
Sequel.migration do
  change do
    create_table(:invoices) do
      primary_key :id
      String :client_name, null: false
      String :currency, null: false, default: 'AUD'
      Float :amount, null: false
      Integer :item_count, null: false, default: 1
      Float :unit_price, null: false
      String :status, null: false, default: 'Generated'
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
```

**Step 2: Create Invoice model**

```ruby
# app/models/invoice.rb
require 'sequel'

DB = Sequel.connect(ENV.fetch('DATABASE_URL', 'sqlite://invoices.sqlite3'))
Sequel.extension :migration
Sequel::Migrator.run(DB, 'db/migrations')

class Invoice < Sequel::Model(DB[:invoices])
  def total
    (unit_price * item_count).round(2)
  end
end
```

**Step 3: Verify model loads**

Run: `ruby -r ./app/models/invoice -e "puts Invoice.count"`
Expected: `0`

**Step 4: Commit**

```bash
git add app/models/invoice.rb db/migrations/001_create_invoices.rb
git commit -m "feat: add Invoice model with SQLite migration"
```

---

### Task 3: XML Generator Service

**Files:**
- Create: `app/services/xml_generator.rb`

**Step 1: Write the service**

```ruby
# app/services/xml_generator.rb
require 'nokogiri'

class XmlGenerator
  def self.generate(invoice)
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.Invoice(version: '1.0') {
        xml.Client {
          xml.Name invoice.client_name
        }
        xml.Currency invoice.currency
        xml.LineItems {
          invoice.item_count.times do |i|
            xml.Item(number: i + 1) {
              xml.Description "Service Item #{i + 1}"
              xml.UnitPrice invoice.unit_price.to_s
              xml.Quantity 1
            }
          end
        }
        xml.Total invoice.total.to_s
        xml.Status invoice.status
        xml.GeneratedAt invoice.created_at.to_s
      }
    end
    builder.to_xml
  end
end
```

**Step 2: Manually verify output**

Run:
```bash
ruby -r ./app/models/invoice -r ./app/services/xml_generator -e "
  inv = Invoice.new(client_name: 'Test Co', currency: 'AUD', amount: 300.0, item_count: 3, unit_price: 100.0, status: 'Generated')
  puts XmlGenerator.generate(inv)
"
```
Expected: Valid XML with `Invoice`, `Client/Name`, `LineItems/Item`, `Total` elements printed

**Step 3: Commit**

```bash
git add app/services/xml_generator.rb
git commit -m "feat: add Nokogiri XML generator service"
```

---

### Task 4: PDF Generator Service

**Files:**
- Create: `app/services/pdf_generator.rb`

**Step 1: Write the service**

```ruby
# app/services/pdf_generator.rb
require 'prawn'

class PdfGenerator
  def self.generate(invoice)
    Prawn::Document.new do |pdf|
      pdf.text "INVOICE ##{invoice.id}", size: 24, style: :bold
      pdf.move_down 10
      pdf.text "Client: #{invoice.client_name}"
      pdf.text "Currency: #{invoice.currency}"
      pdf.move_down 10

      pdf.text "Line Items:", style: :bold
      invoice.item_count.times do |i|
        pdf.text "  Item #{i + 1}: #{invoice.currency} #{invoice.unit_price}"
      end

      pdf.move_down 10
      pdf.text "Total: #{invoice.currency} #{invoice.total}", style: :bold
      pdf.text "Status: #{invoice.status}"
      pdf.text "Generated: #{invoice.created_at}"
    end.render
  end
end
```

**Step 2: Verify it generates binary PDF**

Run:
```bash
ruby -r ./app/models/invoice -r ./app/services/pdf_generator -e "
  inv = Invoice.new(id: 1, client_name: 'Test Co', currency: 'AUD', amount: 300.0, item_count: 3, unit_price: 100.0, status: 'Generated', created_at: Time.now)
  pdf = PdfGenerator.generate(inv)
  puts pdf[0..3] == '%PDF' ? 'Valid PDF' : 'INVALID'
"
```
Expected: `Valid PDF`

**Step 3: Commit**

```bash
git add app/services/pdf_generator.rb
git commit -m "feat: add Prawn PDF generator service"
```

---

### Task 5: Sinatra App Routes + Views

**Files:**
- Create: `app/app.rb`
- Create: `app/views/layout.erb`
- Create: `app/views/dashboard.erb`

**Step 1: Create the Sinatra app**

```ruby
# app/app.rb
require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require_relative 'models/invoice'
require_relative 'services/xml_generator'
require_relative 'services/pdf_generator'

set :root, File.dirname(__FILE__)
set :port, 4567
set :bind, '0.0.0.0'

# UI Routes
get '/' do
  @invoices = Invoice.order(Sequel.desc(:created_at)).all
  erb :dashboard
end

post '/invoices' do
  invoice = Invoice.create(
    client_name: params[:client_name],
    currency: params[:currency],
    amount: params[:amount].to_f,
    item_count: params[:item_count].to_i,
    unit_price: params[:unit_price].to_f,
    status: 'Generated'
  )
  redirect '/'
end

# API Routes
post '/api/invoices' do
  content_type :json
  data = JSON.parse(request.body.read)
  invoice = Invoice.create(
    client_name: data['client_name'],
    currency: data['currency'] || 'AUD',
    amount: data['amount'].to_f,
    item_count: data['item_count'].to_i,
    unit_price: data['unit_price'].to_f,
    status: 'Generated'
  )
  status 201
  { id: invoice.id, status: invoice.status }.to_json
end

get '/api/invoices/:id/xml' do
  invoice = Invoice[params[:id].to_i]
  halt 404, 'Invoice not found' unless invoice
  content_type 'application/xml'
  XmlGenerator.generate(invoice)
end

get '/api/invoices/:id/pdf' do
  invoice = Invoice[params[:id].to_i]
  halt 404, 'Invoice not found' unless invoice
  content_type 'application/pdf'
  headers['Content-Disposition'] = "attachment; filename=\"invoice_#{invoice.id}.pdf\""
  PdfGenerator.generate(invoice)
end
```

**Step 2: Create layout.erb**

```html
<!-- app/views/layout.erb -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Invoice Generator</title>
  <style>
    body { font-family: Arial, sans-serif; max-width: 900px; margin: 40px auto; padding: 0 20px; }
    table { width: 100%; border-collapse: collapse; margin-top: 20px; }
    th, td { padding: 10px; border: 1px solid #ddd; text-align: left; }
    th { background: #f4f4f4; }
    form { background: #f9f9f9; padding: 20px; border-radius: 6px; margin-bottom: 30px; }
    input, select { padding: 8px; margin: 4px 0 12px; width: 100%; box-sizing: border-box; }
    button { padding: 10px 20px; background: #0066cc; color: white; border: none; border-radius: 4px; cursor: pointer; }
    button:hover { background: #0052a3; }
    a { color: #0066cc; }
    .empty { color: #888; font-style: italic; }
  </style>
</head>
<body>
  <h1>Invoice Generator</h1>
  <%= yield %>
</body>
</html>
```

**Step 3: Create dashboard.erb**

```html
<!-- app/views/dashboard.erb -->
<h2>Create New Invoice</h2>
<form id="invoice-form" action="/invoices" method="post">
  <label>Client Name</label>
  <input type="text" id="client_name" name="client_name" data-testid="client-name" required>

  <label>Currency</label>
  <select id="currency" name="currency" data-testid="currency">
    <option value="AUD">AUD</option>
    <option value="USD">USD</option>
    <option value="EUR">EUR</option>
  </select>

  <label>Unit Price</label>
  <input type="number" id="unit_price" name="unit_price" data-testid="unit-price" step="0.01" required>

  <label>Number of Items</label>
  <input type="number" id="item_count" name="item_count" data-testid="item-count" value="1" min="1" required>

  <input type="hidden" name="amount" id="amount" value="0">

  <button type="submit" id="generate-btn" data-testid="generate-btn">Generate Invoice</button>
</form>

<h2>Invoices</h2>
<% if @invoices.empty? %>
  <p class="empty" data-testid="empty-msg">No invoices yet</p>
<% else %>
  <table id="invoice-table" data-testid="invoice-table">
    <thead>
      <tr>
        <th>ID</th><th>Client</th><th>Currency</th><th>Total</th><th>Status</th><th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <% @invoices.each do |inv| %>
        <tr data-testid="invoice-row-<%= inv.id %>">
          <td><%= inv.id %></td>
          <td data-testid="client-<%= inv.id %>"><%= inv.client_name %></td>
          <td data-testid="currency-<%= inv.id %>"><%= inv.currency %></td>
          <td><%= inv.currency %> <%= inv.total %></td>
          <td data-testid="status-<%= inv.id %>"><%= inv.status %></td>
          <td>
            <a href="/api/invoices/<%= inv.id %>/xml" data-testid="xml-link-<%= inv.id %>">XML</a> |
            <a href="/api/invoices/<%= inv.id %>/pdf" data-testid="pdf-link-<%= inv.id %>">PDF</a>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
<% end %>

<script>
  document.getElementById('invoice-form').addEventListener('submit', function() {
    var price = parseFloat(document.getElementById('unit_price').value) || 0;
    var count = parseInt(document.getElementById('item_count').value) || 1;
    document.getElementById('amount').value = (price * count).toFixed(2);
  });
</script>
```

**Step 4: Start the app and verify manually**

Run: `bundle exec ruby app/app.rb`
Open: `http://localhost:4567`
Expected: Dashboard loads, form visible, "No invoices yet" shown

**Step 5: Commit**

```bash
git add app/app.rb app/views/
git commit -m "feat: add Sinatra routes and ERB dashboard view"
```

---

### Task 6: Cucumber + Selenium Setup

**Files:**
- Create: `features/support/env.rb`
- Create: `features/support/hooks.rb`
- Create: `pages/invoice_dashboard_page.rb`

**Step 1: Create env.rb**

```ruby
# features/support/env.rb
require 'cucumber'
require 'selenium-webdriver'
require 'rspec/expectations'
require 'net/http'
require 'json'
require 'nokogiri'

BASE_URL = ENV.fetch('BASE_URL', 'http://localhost:4567')

World(RSpec::Matchers)
```

**Step 2: Create hooks.rb**

```ruby
# features/support/hooks.rb
require_relative '../../app/models/invoice'

Before do
  @driver = Selenium::WebDriver.for(:chrome, options: chrome_options)
  @driver.manage.timeouts.implicit_wait = 5
end

After do
  @driver&.quit
  Invoice.dataset.delete
end

def chrome_options
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless') if ENV['CI']
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options
end
```

**Step 3: Create Page Object**

```ruby
# pages/invoice_dashboard_page.rb
class InvoiceDashboardPage
  def initialize(driver)
    @driver = driver
  end

  def visit
    @driver.navigate.to BASE_URL
  end

  def empty_message
    @driver.find_element(css: '[data-testid="empty-msg"]').text
  rescue Selenium::WebDriver::Error::NoSuchElementError
    nil
  end

  def fill_client_name(name)
    @driver.find_element(css: '[data-testid="client-name"]').send_keys(name)
  end

  def select_currency(currency)
    select = Selenium::WebDriver::Support::Select.new(
      @driver.find_element(css: '[data-testid="currency"]')
    )
    select.select_by(:value, currency)
  end

  def fill_unit_price(price)
    @driver.find_element(css: '[data-testid="unit-price"]').send_keys(price.to_s)
  end

  def fill_item_count(count)
    field = @driver.find_element(css: '[data-testid="item-count"]')
    field.clear
    field.send_keys(count.to_s)
  end

  def click_generate
    @driver.find_element(css: '[data-testid="generate-btn"]').click
  end

  def invoice_rows
    @driver.find_elements(css: '[data-testid^="invoice-row-"]')
  end

  def client_names
    @driver.find_elements(css: '[data-testid^="client-"]').map(&:text)
  end

  def currency_for_client(client_name)
    rows = @driver.find_elements(css: '[data-testid^="invoice-row-"]')
    rows.each do |row|
      return row.find_element(css: '[data-testid^="currency-"]').text if row.text.include?(client_name)
    end
    nil
  end

  def status_for_invoice(id)
    @driver.find_element(css: "[data-testid=\"status-#{id}\"]").text
  rescue Selenium::WebDriver::Error::NoSuchElementError
    nil
  end
end
```

**Step 4: Verify Cucumber loads**

Run: `bundle exec cucumber --dry-run`
Expected: No errors (no features yet, but setup valid)

**Step 5: Commit**

```bash
git add features/support/ pages/
git commit -m "feat: add Cucumber/Selenium setup and InvoiceDashboardPage POM"
```

---

### Task 7: UI Feature File + Step Definitions

**Files:**
- Create: `features/invoice_ui.feature`
- Create: `features/step_definitions/ui_steps.rb`

**Step 1: Create invoice_ui.feature**

```gherkin
# features/invoice_ui.feature
Feature: Invoice Dashboard UI

  Scenario: View empty dashboard
    Given I am on the invoice dashboard
    Then I should see "No invoices yet"

  Scenario: Create a new invoice
    Given I am on the invoice dashboard
    When I fill in the invoice form with:
      | client    | Acme Corp |
      | amount    | 1500.00   |
      | currency  | AUD       |
    And I click "Generate Invoice"
    Then I should see "Acme Corp" in the invoice list
    And the invoice status should be "Generated"

  Scenario Outline: Create invoices in multiple currencies
    Given I am on the invoice dashboard
    When I create an invoice for "<client>" with amount "<amount>" in "<currency>"
    Then the invoice list should show "<currency>" for "<client>"

    Examples:
      | client      | amount   | currency |
      | Globex Ltd  | 2500.00  | USD      |
      | Initech     | 980.50   | EUR      |
      | Umbrella Co | 15000.00 | AUD      |
```

**Step 2: Create ui_steps.rb**

```ruby
# features/step_definitions/ui_steps.rb
require_relative '../../pages/invoice_dashboard_page'

Given('I am on the invoice dashboard') do
  @page = InvoiceDashboardPage.new(@driver)
  @page.visit
end

Then('I should see {string}') do |text|
  expect(@page.empty_message).to eq(text)
end

When('I fill in the invoice form with:') do |table|
  data = table.rows_hash
  @page.fill_client_name(data['client'])
  @page.select_currency(data['currency']) if data['currency']
  price = data['amount'].to_f
  @page.fill_unit_price(price)
  @page.fill_item_count(1)
end

When('I click {string}') do |_button_text|
  @page.click_generate
end

Then('I should see {string} in the invoice list') do |client_name|
  expect(@page.client_names).to include(client_name)
end

Then('the invoice status should be {string}') do |expected_status|
  rows = @page.invoice_rows
  expect(rows).not_to be_empty
  last_id = rows.last.attribute('data-testid').split('-').last
  expect(@page.status_for_invoice(last_id)).to eq(expected_status)
end

When('I create an invoice for {string} with amount {string} in {string}') do |client, amount, currency|
  @page.fill_client_name(client)
  @page.select_currency(currency)
  @page.fill_unit_price(amount.to_f)
  @page.fill_item_count(1)
  @page.click_generate
end

Then('the invoice list should show {string} for {string}') do |currency, client|
  expect(@page.currency_for_client(client)).to eq(currency)
end
```

**Step 3: Run UI scenarios (app must be running)**

In terminal 1: `bundle exec ruby app/app.rb`
In terminal 2: `bundle exec cucumber features/invoice_ui.feature`
Expected: All 5 scenarios (3 outline rows) pass

**Step 4: Commit**

```bash
git add features/invoice_ui.feature features/step_definitions/ui_steps.rb
git commit -m "feat: add UI feature file and Selenium step definitions"
```

---

### Task 8: API Feature File + Step Definitions

**Files:**
- Create: `features/invoice_api.feature`
- Create: `features/step_definitions/api_steps.rb`

**Step 1: Create invoice_api.feature**

```gherkin
# features/invoice_api.feature
Feature: Invoice API - XML and PDF Generation

  Scenario: Generate XML invoice via API
    Given the invoice API is running
    When I POST to "/api/invoices" with valid invoice data
    Then the response status should be 201
    And the response body should contain a valid invoice ID

  Scenario: Validate XML invoice structure
    Given an invoice exists with ID "1"
    When I GET "/api/invoices/1/xml"
    Then the response content-type should be "application/xml"
    And the XML should contain element "Invoice/Client/Name"
    And the XML should contain element "Invoice/LineItems/Item"
    And the XML element "Invoice/Total" should equal "1500.00"

  Scenario: Download PDF invoice
    Given an invoice exists with ID "1"
    When I GET "/api/invoices/1/pdf"
    Then the response content-type should be "application/pdf"
    And the PDF should not be empty

  Scenario Outline: Generate invoices with different line item counts
    Given the invoice API is running
    When I create an invoice with "<items>" line items at "<price>" each
    Then the XML total should equal "<expected_total>"

    Examples:
      | items | price  | expected_total |
      | 1     | 100.00 | 100.00         |
      | 3     | 250.00 | 750.00         |
      | 5     | 99.99  | 499.95         |
```

**Step 2: Create api_steps.rb**

```ruby
# features/step_definitions/api_steps.rb
require 'net/http'
require 'json'
require 'nokogiri'
require_relative '../../app/models/invoice'

VALID_INVOICE_DATA = {
  client_name: 'Acme Corp',
  currency: 'AUD',
  amount: 1500.0,
  item_count: 1,
  unit_price: 1500.0
}.freeze

Given('the invoice API is running') do
  uri = URI("#{BASE_URL}/api/invoices")
  Net::HTTP.get_response(uri)
rescue StandardError
  raise 'Sinatra app is not running. Start it with: bundle exec ruby app/app.rb'
end

Given('an invoice exists with ID {string}') do |_id|
  Invoice.dataset.delete
  data = VALID_INVOICE_DATA.dup
  uri = URI("#{BASE_URL}/api/invoices")
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
  request.body = data.to_json
  @last_response = http.request(request)
  @invoice_id = JSON.parse(@last_response.body)['id']
end

When('I POST to {string} with valid invoice data') do |path|
  uri = URI("#{BASE_URL}#{path}")
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
  request.body = VALID_INVOICE_DATA.to_json
  @last_response = http.request(request)
end

When('I GET {string}') do |path|
  actual_path = path.gsub('/1/', "/#{@invoice_id}/")
  uri = URI("#{BASE_URL}#{actual_path}")
  @last_response = Net::HTTP.get_response(uri)
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
  uri = URI("#{BASE_URL}/api/invoices")
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
  request.body = data.to_json
  response = http.request(request)
  @invoice_id = JSON.parse(response.body)['id']

  xml_uri = URI("#{BASE_URL}/api/invoices/#{@invoice_id}/xml")
  @last_response = Net::HTTP.get_response(xml_uri)
end

Then('the XML total should equal {string}') do |expected_total|
  doc = Nokogiri::XML(@last_response.body)
  total = doc.at_xpath('//Total').text
  expect(total).to eq(expected_total)
end
```

**Step 3: Run API scenarios**

In terminal 1: `bundle exec ruby app/app.rb` (if not already running)
In terminal 2: `bundle exec cucumber features/invoice_api.feature`
Expected: All 6 scenarios pass

**Step 4: Run full suite**

Run: `bundle exec cucumber`
Expected: All scenarios pass

**Step 5: Commit**

```bash
git add features/invoice_api.feature features/step_definitions/api_steps.rb
git commit -m "feat: add API feature file and XML/PDF step definitions"
```

---

### Task 9: GitHub Actions CI

**Files:**
- Create: `.github/workflows/test.yml`

**Step 1: Create workflow**

```yaml
# .github/workflows/test.yml
name: Cucumber Test Suite

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      - name: Set up Chrome
        uses: browser-actions/setup-chrome@v1

      - name: Start Sinatra app in background
        run: bundle exec ruby app/app.rb &
        env:
          APP_ENV: production
          CI: true

      - name: Wait for app to be ready
        run: sleep 3

      - name: Run Cucumber tests
        run: |
          mkdir -p reports
          bundle exec cucumber --format html --out reports/cucumber_report.html --format pretty
        env:
          CI: true

      - name: Upload test report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: cucumber-report
          path: reports/cucumber_report.html
```

**Step 2: Commit**

```bash
git add .github/workflows/test.yml
git commit -m "ci: add GitHub Actions pipeline with Cucumber HTML report"
```

---

### Task 10: Push to GitHub

**Step 1: Create GitHub repo and push**

Run:
```bash
gh repo create interview-invoice-demo --public --source=. --remote=origin --push
```

Or manually:
```bash
git remote add origin https://github.com/<your-username>/interview-invoice-demo.git
git push -u origin main
```

**Step 2: Verify CI runs**

Open GitHub → Actions tab → confirm "Cucumber Test Suite" workflow runs and passes
Download artifact: `cucumber-report` → open `cucumber_report.html` in browser

**Step 3: Final local smoke test**

```bash
bundle exec cucumber --format html --out reports/cucumber_report.html --format pretty
open reports/cucumber_report.html
```

Expected: All scenarios green in the HTML report — ready to demo to interviewer
