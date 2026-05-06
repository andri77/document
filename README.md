# Invoice Demo App

A Ruby/Sinatra invoice system demonstrating BDD automation with Cucumber — UI testing via Selenium and API testing with XML/PDF validation. Built as a portfolio piece for the EY Automation Tester role.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Browser / Test Client                     │
│              (Selenium WebDriver  │  Net::HTTP / Postman)        │
└─────────────────┬───────────────────────────┬───────────────────┘
                  │ HTTP                       │ HTTP
                  ▼                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Sinatra Web Server (port 4567)                │
│                                                                  │
│  ┌──────────────────────┐    ┌──────────────────────────────┐   │
│  │      UI Routes        │    │         API Routes            │   │
│  │  GET  /               │    │  POST /api/invoices           │   │
│  │  POST /invoices       │    │  GET  /api/invoices/:id/xml   │   │
│  └──────────┬───────────┘    │  GET  /api/invoices/:id/pdf   │   │
│             │                └──────────────┬───────────────┘   │
│             │                               │                    │
│             ▼                               ▼                    │
│  ┌──────────────────┐       ┌───────────────────────────────┐   │
│  │   ERB Templates  │       │         Services               │   │
│  │  views/layout    │       │  ┌─────────────────────────┐  │   │
│  │  views/dashboard │       │  │  XmlGenerator (Nokogiri)│  │   │
│  └──────────────────┘       │  └─────────────────────────┘  │   │
│                              │  ┌─────────────────────────┐  │   │
│                              │  │  PdfGenerator (Prawn)   │  │   │
│                              │  └─────────────────────────┘  │   │
│                              └───────────────────────────────┘   │
│                                             │                    │
│             ┌───────────────────────────────┘                    │
│             ▼                                                     │
│  ┌──────────────────────┐                                        │
│  │   Invoice Model       │                                        │
│  │   (Sequel ORM)        │                                        │
│  └──────────┬───────────┘                                        │
└─────────────┼───────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────┐
│   SQLite Database        │
│   (invoice_test.db)      │
└─────────────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                    Cucumber BDD Test Suite                        │
│                                                                  │
│  features/                                                        │
│  ├── invoice_ui.feature ──────► ui_steps.rb                      │
│  │                                   │                            │
│  │                                   ▼                            │
│  │                        InvoiceDashboardPage (POM)              │
│  │                         pages/invoice_dashboard_page.rb        │
│  │                                   │                            │
│  │                                   ▼                            │
│  │                        Selenium WebDriver ──► Chrome           │
│  │                                                                │
│  └── invoice_api.feature ────► api_steps.rb                      │
│                                    │                              │
│                                    ▼                              │
│                          InvoiceApiClient (POM)                   │
│                          pages/invoice_api_client.rb              │
│                                    │                              │
│                                    ▼                              │
│                          Net::HTTP ──► Sinatra API                │
│                          Nokogiri (XML assertions)                │
│                                                                   │
│  support/env.rb            — bootstrap: BASE_URL, RSpec matchers  │
│  support/hooks.rb          — BeforeAll auto-start, DB wipe, sleep │
│  support/pdf_comparison.rb — PDF→PNG conversion, mask, diff        │
└─────────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                    CI/CD — GitHub Actions                         │
│                                                                  │
│  Push / PR to main                                               │
│       │                                                          │
│       ▼                                                          │
│  1. Setup Ruby 3.3 + Bundler cache                               │
│  2. Setup Chrome (headless)                                      │
│  3. Start Sinatra in background                                  │
│  4. Run API Cucumber suite → reports/cucumber_report.html        │
│  5. Run UI Cucumber suite  → reports/cucumber_ui_report.html     │
│  6. Upload reports as artifact (retained on failure too)         │
└─────────────────────────────────────────────────────────────────┘
```

### Component Overview

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Web server | Sinatra 3.2 + Puma | Handles UI and API routes |
| ORM | Sequel 5.x | Maps `Invoice` model to SQLite |
| Database | SQLite 3 | Zero-config local and CI storage |
| XML generation | Nokogiri | Builds structured XML invoice documents |
| PDF generation | Prawn | Renders printable PDF invoices |
| UI templates | ERB | Server-side rendered dashboard |
| UI tests | Cucumber 9 + Selenium WebDriver 4 | BDD-driven browser automation |
| API tests | Cucumber 9 + Net::HTTP | HTTP-level API and XML validation |
| UI POM | `pages/invoice_dashboard_page.rb` | Encapsulates all dashboard selectors and Selenium interactions |
| API POM | `pages/invoice_api_client.rb` | Encapsulates all HTTP calls (`create`, `get_xml`, `get_pdf`) |
| CI/CD | GitHub Actions | Automated test run on every push/PR |

---

## Project Structure

```
document/
├── app/
│   ├── app.rb                        # Sinatra routes + server entry point (port 4567)
│   ├── models/
│   │   └── invoice.rb                # Sequel model — maps to invoices table in SQLite
│   ├── services/
│   │   ├── xml_generator.rb          # Nokogiri XML builder for /api/invoices/:id/xml
│   │   └── pdf_generator.rb          # Prawn PDF builder for /api/invoices/:id/pdf
│   └── views/
│       ├── layout.erb                # Shared HTML wrapper
│       └── dashboard.erb             # Invoice list + create form
├── features/
│   ├── invoice_ui.feature            # Selenium UI scenarios (dashboard, form, currencies)
│   ├── invoice_api.feature           # API scenarios (POST, XML structure, PDF download)
│   ├── step_definitions/
│   │   ├── ui_steps.rb               # UI step implementations — delegates to InvoiceDashboardPage
│   │   └── api_steps.rb              # API step implementations — delegates to InvoiceApiClient
│   └── support/
│       ├── env.rb                    # Cucumber world setup (BASE_URL, RSpec matchers)
│       ├── hooks.rb                  # BeforeAll auto-start, Before/After DB wipe, demo sleep
│       └── pdf_comparison.rb         # PDF→PNG conversion, timestamp masking, pixel diff
├── pages/
│   ├── invoice_dashboard_page.rb     # UI Page Object — dashboard selectors and Selenium actions
│   └── invoice_api_client.rb         # API Page Object — HTTP client (create, get_xml, get_pdf)
├── db/
│   └── migrations/
│       └── 001_create_invoices.rb    # Sequel migration for the invoices table
├── .github/
│   └── workflows/
│       └── test.yml                  # GitHub Actions CI pipeline
├── docs/
│   ├── postman/
│   │   └── invoice-api-collection.json  # Postman collection for XML API testing
│   └── superpowers/                  # Design specs and implementation plans
├── reports/                          # Generated HTML test reports (gitignored)
├── cucumber.yml                      # Default Cucumber options (--publish-quiet)
├── Gemfile
├── Gemfile.lock
└── README.md
```

---

## Prerequisites

| Requirement | Version | Check |
|-------------|---------|-------|
| Ruby | 3.3.x | `ruby -v` |
| Bundler | 4.x | `bundler -v` |
| Google Chrome | Latest stable | `google-chrome --version` or `open -a "Google Chrome"` |
| ChromeDriver | Matches Chrome | Managed automatically by selenium-webdriver 4.x |
| SQLite | 3.x | `sqlite3 --version` |
| ImageMagick | 6 or 7 | `magick --version` |
| Ghostscript | Any recent | `gs --version` |

> **ChromeDriver note:** selenium-webdriver 4.6+ manages ChromeDriver automatically via the Chrome for Testing service. No manual ChromeDriver install is needed.

> **macOS system Ruby warning:** macOS ships with Ruby 2.6 at `/usr/bin/ruby`. This project requires Ruby 3.3. If you see a `Could not find 'bundler'` error, your terminal is using the wrong Ruby — see the fix below.

### Install Ruby 3.3 (macOS)

```bash
brew install ruby@3.3
```

Then add it to your shell PATH **permanently** (do this once):

```bash
echo 'export PATH="/opt/homebrew/opt/ruby@3.3/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Verify the right Ruby is active:

```bash
ruby -v        # should show ruby 3.3.x
bundler -v     # should show Bundler 4.x
```

> **Alternative:** Use rbenv or RVM to manage multiple Ruby versions:
> ```bash
> brew install rbenv ruby-build
> rbenv install 3.3.11
> rbenv local 3.3.11   # sets version for this project directory only
> ```

### Install system dependencies (macOS)

```bash
brew install imagemagick ghostscript sqlite3
```

---

## Quick Start

A single shell script handles starting the app and running tests:

```bash
./run.sh app       # Start the server (foreground, Ctrl+C to stop)
./run.sh test      # Start app + run full suite + stop app
./run.sh api       # Start app + run API tests only + stop app
./run.sh ui        # Start app + run UI tests only + stop app
./run.sh report    # Same as 'test' but opens HTML reports when done
```

**Environment variables:**

```bash
PORT=8080 ./run.sh app              # Use a different port
HEADLESS=true ./run.sh ui           # Run Chrome headless
BASE_URL=http://staging ./run.sh test  # Test against a remote app
```

The script:
- Kills any stale process on the port before starting
- Polls until the server responds (up to 15 s) before launching tests
- Runs API and UI suites independently so one failure doesn't skip the other
- Writes HTML reports to `reports/`
- Stops the server automatically on exit, interrupt, or error

---

## Installation

```bash
# 1. Clone the repository
git clone <repository-url>
cd document

# 2. Install dependencies
bundle install
```

That's it — SQLite requires no server setup and ChromeDriver is managed automatically.

---

## Running the App

### Start the server

```bash
bundle exec ruby app/app.rb
```

The server starts on **http://localhost:4567**

Open your browser to [http://localhost:4567](http://localhost:4567) to see the invoice dashboard.

### Stop the server

Press `Ctrl+C` in the terminal.

### Change the port

```bash
PORT=8080 bundle exec ruby app/app.rb
```

---

## Running Tests

### Prerequisites for tests

The test suite auto-starts the Sinatra app if it is not already running (`BeforeAll` in `features/support/hooks.rb` spawns the server and waits up to 15 s for it to respond). You can also start it manually beforehand — the hook detects a running server and skips the spawn.

### Run the full suite

```bash
bundle exec cucumber
```

### Run only API tests

```bash
bundle exec cucumber features/invoice_api.feature
```

### Run only UI tests

```bash
bundle exec cucumber features/invoice_ui.feature
```

### Run with pretty console output + HTML report

```bash
mkdir -p reports
bundle exec cucumber \
  --format html --out reports/cucumber_report.html \
  --format pretty
```

Open `reports/cucumber_report.html` in your browser after the run.

### Run a specific scenario by tag

```bash
# Tag a scenario in the .feature file with @smoke
bundle exec cucumber --tags @smoke
```

### Run tests headless (no visible browser window)

```bash
HEADLESS=true bundle exec cucumber features/invoice_ui.feature
```

### Run against a different environment

```bash
BASE_URL=https://staging.example.com bundle exec cucumber
```

---

## Command Line Options

> **Tip:** `./run.sh` handles the Ruby PATH automatically. If you're running `bundle exec` directly in your terminal and see a bundler version error, either add Homebrew Ruby to your PATH (see [Prerequisites](#prerequisites)) or prefix commands with `PATH="/opt/homebrew/opt/ruby@3.3/bin:$PATH"`.

### Filtering by tag

Every scenario is tagged — pass `--tags` to run a subset.

```bash
# API tests only
bundle exec cucumber --tags @api

# UI tests only
bundle exec cucumber --tags @ui

# Visual PDF comparison only
bundle exec cucumber --tags @pdf_visual

# Combine tags: API AND pdf_visual (both tags must be present)
bundle exec cucumber --tags "@api and @pdf_visual"

# Exclude a tag: everything except UI
bundle exec cucumber --tags "not @ui"
```

Available tags in this project:

| Tag | Scenarios covered |
|-----|-------------------|
| `@api` | All API scenarios (XML, PDF download, visual baseline) |
| `@ui` | All Selenium browser scenarios |
| `@pdf_visual` | Visual PDF baseline comparison only |

### Browser options

```bash
# Run Chrome headless (no visible window)
HEADLESS=true bundle exec cucumber features/invoice_ui.feature

# Run with a visible Chrome window (default locally)
bundle exec cucumber features/invoice_ui.feature

# CI mode — forces headless, skips demo sleep between scenarios
CI=true bundle exec cucumber
```

### Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `BASE_URL` | `http://localhost:4567` | App URL for both UI and API tests |
| `HEADLESS` | *(unset)* | Set to `true` to run Chrome headless |
| `CI` | *(unset)* | Set to `true` in CI — enables headless and skips demo sleep |
| `PDF_DIFF_THRESHOLD` | `0.0` | Max allowed pixel difference % for visual PDF comparison |
| `PDF_BASELINE_DIR` | `features/fixtures/baselines` | Where baseline PNGs are stored |
| `PDF_ACTUAL_DIR` | `features/fixtures/actuals` | Where per-run actual + diff PNGs are written |

**Examples:**

```bash
# Run API tests against a staging server
BASE_URL=https://staging.example.com bundle exec cucumber --tags @api

# Run visual PDF test with a 0.5% pixel tolerance
PDF_DIFF_THRESHOLD=0.5 bundle exec cucumber --tags @pdf_visual

# Full suite, headless, against a custom URL
HEADLESS=true BASE_URL=http://localhost:8080 bundle exec cucumber

# Regenerate the PDF visual baseline (delete it first, then run)
rm features/fixtures/baselines/invoice_standard.png
bundle exec cucumber --tags @pdf_visual
```

### Output formats

```bash
# Pretty console output (default)
bundle exec cucumber --format pretty

# HTML report
mkdir -p reports
bundle exec cucumber --format html --out reports/cucumber_report.html --format pretty

# JSON output (for integration with other tools)
bundle exec cucumber --format json --out reports/cucumber_report.json
```

---

## Test Reports

HTML reports are written to `reports/` (gitignored locally, uploaded as CI artifacts):

| Report | Command |
|--------|---------|
| API test report | `reports/cucumber_report.html` |
| UI test report | `reports/cucumber_ui_report.html` |

---

## Database

The app uses SQLite with a single `invoices` table. The database file is created automatically on first run.

### Run migrations manually

```bash
bundle exec ruby db/migrations/001_create_invoices.rb
```

### Reset the database

```bash
rm -f invoice_test.db
bundle exec ruby db/migrations/001_create_invoices.rb
```

---

## API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/` | Invoice dashboard (HTML) |
| `POST` | `/invoices` | Create invoice via form submission |
| `POST` | `/api/invoices` | Create invoice (JSON body, returns `{id, status}`) |
| `GET` | `/api/invoices/:id/xml` | Download XML invoice document |
| `GET` | `/api/invoices/:id/pdf` | Download PDF invoice document |

### Example API calls

```bash
# Create an invoice
curl -s -X POST http://localhost:4567/api/invoices \
  -H "Content-Type: application/json" \
  -d '{"client_name":"Acme Corp","currency":"AUD","amount":1500.00,"item_count":3,"unit_price":500.00}' | jq .

# Download XML
curl -s http://localhost:4567/api/invoices/1/xml

# Download PDF
curl -s http://localhost:4567/api/invoices/1/pdf -o invoice_1.pdf
```

---

## CI/CD

The GitHub Actions pipeline runs automatically on every push and pull request to `main`.

**Pipeline steps:**

1. Check out code
2. Set up Ruby 3.3 with Bundler cache
3. Set up Chrome (headless)
4. Start Sinatra server in the background
5. Run API Cucumber suite → `reports/cucumber_report.html`
6. Run UI Cucumber suite (headless) → `reports/cucumber_ui_report.html`
7. Upload both reports as a build artifact (runs even on test failure)

**View reports:** Go to the Actions tab in GitHub → select a run → download the `cucumber-reports` artifact.

---

## Key Design Decisions

- **Symmetric Page Object Model** — both layers have a dedicated page object in `pages/`:
  - `InvoiceDashboardPage` — wraps every Selenium interaction (locators, waits, form helpers)
  - `InvoiceApiClient` — wraps every HTTP call (`create`, `get_xml`, `get_pdf`); step definitions contain only orchestration and assertions, no transport code
  - `pages/` lives at the project root so objects can be shared across feature files without circular requires
- **Auto-starting server** — `BeforeAll` in `hooks.rb` checks whether the app is already up and spawns it if not, so `bundle exec cucumber` works without a separate server terminal. `AfterAll` only terminates the process when Cucumber started it — if `run.sh` manages the server, Cucumber leaves it alone.
- **Test isolation** — `hooks.rb` wipes the database after each scenario, so every scenario starts with a clean slate and order-independence is guaranteed.
- **No external test tool dependency** — API tests use Ruby's built-in `Net::HTTP` rather than requiring Postman/SoapUI locally. A Postman collection (`docs/postman/invoice-api-collection.json`) is provided for exploratory and manual testing.
- **SQLite** — chosen for zero-config setup in both local development and GitHub Actions, with no database server required.
- **ChromeDriver auto-management** — selenium-webdriver 4.6+ downloads the correct ChromeDriver version automatically, eliminating version mismatch issues in CI.
