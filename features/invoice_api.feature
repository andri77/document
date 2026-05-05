@api
Feature: Invoice API - XML and PDF Generation

  @api
  Scenario: Generate XML invoice via API
    Given the invoice API is running
    When I POST to "/api/invoices" with valid invoice data
    Then the response status should be 201
    And the response body should contain a valid invoice ID

  @api
  Scenario: Validate XML invoice structure
    Given an invoice exists with ID "1"
    When I GET "/api/invoices/1/xml"
    Then the response content-type should be "application/xml"
    And the XML should contain element "Invoice/Client/Name"
    And the XML should contain element "Invoice/LineItems/Item"
    And the XML element "Invoice/Total" should equal "1500.0"

  @api
  Scenario: Download PDF invoice
    Given an invoice exists with ID "1"
    When I GET "/api/invoices/1/pdf"
    Then the response content-type should be "application/pdf"
    And the PDF should not be empty

  @api
  Scenario Outline: Generate invoices with different line item counts
    Given the invoice API is running
    When I create an invoice with "<items>" line items at "<price>" each
    Then the XML total should equal "<expected_total>"

    Examples:
      | items | price  | expected_total |
      | 1     | 100.0  | 100.0          |
      | 3     | 250.0  | 750.0          |
      | 5     | 99.99  | 499.95         |

  @api @pdf_visual
  Scenario: PDF invoice matches visual baseline
    Given an invoice exists with ID "1"
    When I GET "/api/invoices/1/pdf"
    Then the PDF should match the visual baseline "invoice_standard"
