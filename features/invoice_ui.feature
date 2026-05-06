@ui
Feature: Invoice Dashboard UI

  @ui
  Scenario: View empty dashboard
    Given I am on the invoice dashboard
    Then I should see "No invoices yet"

  @ui1 @pdf_visual
  Scenario: Create a new invoice
    Given I am on the invoice dashboard
    When I fill in the invoice form with:
      | client    | Acme Corp |
      | amount    | 1500.00   |
      | currency  | AUD       |
    And I click "Generate Invoice"
    Then I should see "Acme Corp" in the invoice list
    And the invoice status should be "Generated"
    And the generated invoice PDF should match the visual baseline "invoice_ui_standard"

  @ui
  Scenario Outline: Create invoices in multiple currencies
    Given I am on the invoice dashboard
    When I create an invoice for "<client>" with amount "<amount>" in "<currency>"
    Then the invoice list should show "<currency>" for "<client>"

    Examples:
      | client      | amount   | currency |
      | Globex Ltd  | 2500.00  | USD      |
      | Initech     | 980.50   | EUR      |
      | Umbrella Co | 15000.00 | AUD      |
