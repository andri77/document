# Invoice Demo App — Design Document

**Date:** 2026-05-05  
**Purpose:** Interview demo for EY Automation Tester role

---

## Overview

A Ruby/Sinatra invoice billing system with a full BDD test suite demonstrating:
- Cucumber + Selenium for UI automation
- API testing with XML structure validation
- PDF generation and validation
- Page Object Model (POM)
- GitHub Actions CI with HTML test report

---

## Architecture

### Stack

| Layer | Technology |
|---|---|
| Backend API | Ruby + Sinatra |
| XML Generation | Nokogiri |
| PDF Generation | Prawn |
| Storage | SQLite via Sequel ORM |
| Frontend | ERB templates served by Sinatra |
| UI Tests | Cucumber + Selenium WebDriver (ChromeDriver) |
| API Tests | Cucumber + Net::HTTP |
| CI/CD | GitHub Actions → Cucumber HTML report artifact |

### How It Works

1. User opens dashboard → sees list of invoices
2. User fills form → creates invoice (stored in SQLite)
3. User clicks "Download XML" or "Download PDF" → Sinatra generates and streams the file
4. Cucumber suite drives both UI (Selenium) and API endpoints (HTTP), validating XML structure and PDF content

---

## Project Structure

```
document/
├── app/
│   ├── app.rb                    # Sinatra routes + server entry point
│   ├── models/
│   │   └── invoice.rb            # Sequel model (SQLite)
│   └── services/
│       ├── xml_generator.rb      # Nokogiri XML builder
│       └── pdf_generator.rb      # Prawn PDF builder
│   └── views/
│       ├── layout.erb            # Shared HTML layout
│       └── dashboard.erb         # Invoice list + create form
├── features/
│   ├── invoice_ui.feature        # Selenium UI scenarios
│   ├── invoice_api.feature       # API + XML/PDF validation scenarios
│   ├── step_definitions/
│   │   ├── ui_steps.rb           # Selenium step definitions
│   │   └── api_steps.rb          # HTTP + XML assertion steps
│   └── support/
│       ├── env.rb                # Cucumber bootstrap (browser, base URL)
│       └── hooks.rb              # Before/After hooks (start app, cleanup DB)
├── pages/
│   └── invoice_dashboard_page.rb # Page Object for the dashboard
├── .github/
│   └── workflows/
│       └── test.yml              # GitHub Actions CI
├── reports/                      # Generated test reports (gitignored)
├── Gemfile
├── Gemfile.lock
└── README.md
```

---

## BDD Scenarios

### UI Feature (`features/invoice_ui.feature`)

```gherkin
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

### API Feature (`features/invoice_api.feature`)

```gherkin
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

---

## GitHub Actions CI/CD

- Trigger: push to `main`, pull requests to `main`
- Steps: setup Ruby 3.2 → setup Chrome → start Sinatra → run Cucumber
- Output: HTML report uploaded as artifact (`if: always()`)
- Selenium runs headless in CI via ChromeDriver

---

## Key Design Decisions

- `pages/` at root level — keeps POM separate from features, reusable across feature files
- `hooks.rb` starts Sinatra before suite, resets DB after each scenario for test isolation
- API tests use `Net::HTTP` — no external tool needed, but README notes Postman equivalence
- SQLite chosen for zero-config local + CI setup
