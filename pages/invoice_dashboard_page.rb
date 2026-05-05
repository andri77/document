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
