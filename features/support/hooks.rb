require_relative '../../app/models/invoice'

Before('@ui') do
  @driver = Selenium::WebDriver.for(:chrome, options: chrome_options)
  @driver.manage.timeouts.implicit_wait = 5
end

After('@ui') do
  @driver&.quit
  Invoice.dataset.delete
end

After('not @ui') do
  Invoice.dataset.delete
end

After do
  sleep(rand(2..5)) unless ENV['CI']
end

def chrome_options
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless') if ENV['CI'] || ENV['HEADLESS']
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options
end
