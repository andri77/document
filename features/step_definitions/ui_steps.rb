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
