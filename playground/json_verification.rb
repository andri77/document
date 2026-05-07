require 'json'

JSON_BODY = <<~JSON
  {
    "order": {
      "id": "ORD-20260507-099",
      "status": "processing",
      "placed_at": "2026-05-07T08:15:00Z",
      "currency": "AUD",
      "customer": {
        "id": "C-442",
        "name": "Marco Rossi",
        "email": "marco@example.com",
        "verified": true,
        "loyalty_points": 1450,
        "addresses": [
          {
            "type": "shipping",
            "street": "10 Pitt St",
            "city": "Melbourne",
            "state": "VIC",
            "postcode": "3000",
            "primary": true
          },
          {
            "type": "billing",
            "street": "88 Collins St",
            "city": "Melbourne",
            "state": "VIC",
            "postcode": "3000",
            "primary": false
          }
        ]
      },
      "items": [
        {
          "sku": "NB-512",
          "name": "Notebook Pro 15",
          "category": "electronics",
          "quantity": 1,
          "unit_price": 1299.00,
          "discount": { "type": "percent", "value": 5, "amount": 64.95 },
          "subtotal": 1234.05,
          "taxable": true
        },
        {
          "sku": "BAG-001",
          "name": "Laptop Sleeve 15in",
          "category": "accessories",
          "quantity": 2,
          "unit_price": 39.95,
          "discount": { "type": "fixed", "value": 0, "amount": 0.00 },
          "subtotal": 79.90,
          "taxable": true
        },
        {
          "sku": "CARE-3Y",
          "name": "Care Plan 3 Years",
          "category": "service",
          "quantity": 1,
          "unit_price": 199.00,
          "discount": { "type": "fixed", "value": 0, "amount": 0.00 },
          "subtotal": 199.00,
          "taxable": false
        }
      ],
      "payment": {
        "method": "credit_card",
        "last4": "4242",
        "brand": "Visa",
        "authorised": true,
        "transaction_id": "TXN-7F3A9C"
      },
      "totals": {
        "subtotal": 1512.95,
        "tax": 131.40,
        "shipping": 0.00,
        "grand_total": 1644.35
      },
      "tags": ["online", "express-eligible", "loyalty-member"],
      "metadata": {
        "source": "web",
        "promo_code": null,
        "agent_id": null
      }
    }
  }
JSON

# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

PASS = "\e[32mPASS\e[0m"
FAIL = "\e[31mFAIL\e[0m"
$failures = 0

def check(description, actual, expected)
  if actual == expected
    puts "  #{PASS}  #{description}"
  else
    puts "  #{FAIL}  #{description}"
    puts "         expected: #{expected.inspect}"
    puts "           actual: #{actual.inspect}"
    $failures += 1
  end
end

def section(title)
  puts "\n#{title}"
  puts "-" * title.length
end

# ─────────────────────────────────────────────────────────────────────────────
# TESTS
# ─────────────────────────────────────────────────────────────────────────────

section("JSON — Document structure")

data  = JSON.parse(JSON_BODY)
order = data["order"]
check("Parses without error",                    data.is_a?(Hash),                            true)
check("Top-level key is order",                  data.key?("order"),                          true)
check("Order id",                                order["id"],                                 "ORD-20260507-099")
check("Order status",                            order["status"],                             "processing")
check("Currency",                                order["currency"],                           "AUD")

section("JSON — Customer")

customer = order["customer"]
check("Customer id",                             customer["id"],                              "C-442")
check("Customer name",                           customer["name"],                            "Marco Rossi")
check("Customer verified is boolean true",       customer["verified"],                        true)
check("Loyalty points",                          customer["loyalty_points"],                  1450)
check("Two addresses",                           customer["addresses"].size,                  2)

shipping = customer["addresses"].find { |a| a["type"] == "shipping" }
billing  = customer["addresses"].find { |a| a["type"] == "billing" }
check("Shipping address is primary",             shipping["primary"],                         true)
check("Billing address is not primary",          billing["primary"],                          false)
check("Shipping city",                           shipping["city"],                            "Melbourne")
check("Billing street",                          billing["street"],                           "88 Collins St")

section("JSON — Items")

items = order["items"]
check("Three items",                             items.size,                                  3)
check("First item SKU",                          items[0]["sku"],                             "NB-512")
check("First item unit price",                   items[0]["unit_price"],                      1299.00)
check("First item discount type",                items[0]["discount"]["type"],                "percent")
check("First item discount amount",              items[0]["discount"]["amount"],              64.95)
check("First item subtotal",                     items[0]["subtotal"],                        1234.05)
check("Second item quantity",                    items[1]["quantity"],                        2)
check("Third item category",                     items[2]["category"],                        "service")
check("Third item is not taxable",               items[2]["taxable"],                         false)
check("Two taxable items",                       items.count { |i| i["taxable"] },            2)
check("Sum of subtotals equals totals.subtotal", items.sum { |i| i["subtotal"] }.round(2),   1512.95)

section("JSON — Payment")

payment = order["payment"]
check("Payment method",                          payment["method"],                           "credit_card")
check("Card brand",                              payment["brand"],                            "Visa")
check("Last 4 digits",                           payment["last4"],                            "4242")
check("Payment authorised",                      payment["authorised"],                       true)
check("Transaction ID",                          payment["transaction_id"],                   "TXN-7F3A9C")

section("JSON — Totals")

totals = order["totals"]
check("Subtotal",                                totals["subtotal"],                          1512.95)
check("Tax",                                     totals["tax"],                               131.40)
check("Shipping is free",                        totals["shipping"],                          0.00)
check("Grand total",                             totals["grand_total"],                       1644.35)

section("JSON — Tags & Metadata")

tags = order["tags"]
check("Three tags",                              tags.size,                                   3)
check("Contains express-eligible tag",           tags.include?("express-eligible"),           true)
check("promo_code is nil",                       order["metadata"]["promo_code"].nil?,        true)
check("source is web",                           order["metadata"]["source"],                 "web")

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

puts "\n#{"=" * 40}"
if $failures == 0
  puts "\e[32mAll tests passed.\e[0m"
else
  puts "\e[31m#{$failures} test(s) failed.\e[0m"
  exit 1
end
