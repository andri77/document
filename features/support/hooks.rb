require_relative '../../app/models/invoice'

# ── Auto-start Sinatra if not already running ──────────────────────────────────
module AppProcess
  @pid = nil
  class << self
    attr_accessor :pid
  end
end

BeforeAll do
  next if app_running?

  AppProcess.pid = spawn(
    { 'PORT' => URI.parse(BASE_URL).port.to_s },
    'bundle exec ruby app/app.rb',
    out: File::NULL, err: File::NULL, pgroup: true
  )
  Process.detach(AppProcess.pid)

  deadline = Time.now + 15
  loop do
    break if app_running?
    raise 'Sinatra app did not start within 15 seconds' if Time.now > deadline
    sleep 0.5
  end
end

AfterAll do
  next unless AppProcess.pid

  begin
    Process.kill('TERM', -Process.getpgid(AppProcess.pid))
  rescue Errno::ESRCH, Errno::EPERM
    nil
  end
end

def app_running?
  Net::HTTP.get_response(URI("#{BASE_URL}/"))
  true
rescue StandardError
  false
end

# ── Selenium setup/teardown ────────────────────────────────────────────────────
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
